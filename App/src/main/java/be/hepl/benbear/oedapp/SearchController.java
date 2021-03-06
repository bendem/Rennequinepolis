package be.hepl.benbear.oedapp;

import be.hepl.benbear.oedapp.jdbc.ResultSetExtractor;
import be.hepl.benbear.oedapp.jdbc.SwappableConnection;
import be.hepl.benbear.oedapp.parser.SearchParser;
import javafx.beans.property.ReadOnlyObjectWrapper;
import javafx.concurrent.Task;
import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.control.*;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.input.KeyCode;
import javafx.scene.input.MouseButton;
import oracle.jdbc.OracleTypes;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.net.URL;
import java.sql.CallableStatement;
import java.sql.Date;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.ResourceBundle;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

public class SearchController implements Initializable {

    private final SearchApplication app;
    private final SearchParser parser;
    @FXML private TextField searchField;
    @FXML private Button searchButton;
    @FXML private Button searchHelpButton;
    @FXML private TableView<Movie> searchResultTable;
    @FXML private Label countText;
    @FXML private TableColumn<Movie, Integer> idColumn;
    @FXML private TableColumn<Movie, ImageView> imageColumn;
    @FXML private TableColumn<Movie, String> titleColumn;
    @FXML private TableColumn<Movie, String> statusColumn;
    @FXML private TableColumn<Movie, LocalDate> releaseDateColumn;
    @FXML private TableColumn<Movie, String> taglineColumn;
    @FXML private ImageView loadingImage;
    private String lastSearch = "";
    private FetchTask<Movie> task;

    public SearchController(SearchApplication app) {
        this.app = app;
        parser = new SearchParser("title");
    }

    @Override
    public void initialize(URL location, ResourceBundle resources) {
        searchButton.setOnAction(e -> onSearch());
        searchHelpButton.setOnAction(e -> onHelp());
        searchResultTable.setOnMouseClicked(e -> {
            if(e.getButton() != MouseButton.PRIMARY || e.getClickCount() != 2) {
                return;
            }
            showDetails();
        });
        searchResultTable.setOnKeyPressed(e -> {
            if(e.getCode() != KeyCode.ENTER) {
                return;
            }
            showDetails();
        });

        idColumn.setCellValueFactory(feature -> new ReadOnlyObjectWrapper<>(feature.getValue().getId()));
        imageColumn.setCellValueFactory(feature -> new ReadOnlyObjectWrapper<>(new ImageView(feature.getValue().getImage())));
        titleColumn.setCellValueFactory(feature -> new ReadOnlyObjectWrapper<>(feature.getValue().getTitle()));
        statusColumn.setCellValueFactory(feature -> new ReadOnlyObjectWrapper<>(feature.getValue().getStatus()));
        releaseDateColumn.setCellValueFactory(feature -> new ReadOnlyObjectWrapper<>(feature.getValue().getReleaseDate()));
        taglineColumn.setCellValueFactory(feature -> new ReadOnlyObjectWrapper<>(feature.getValue().getTagline()));

        loadingImage.setImage(new Image(new ByteArrayInputStream(app.getLoadingImage())));
        loadingImage.setVisible(false);
    }

    private void showDetails() {
        Movie selected = searchResultTable.getSelectionModel().getSelectedItem();
        if(selected == null) {
            return;
        }
        try {
            MovieDetailsController controller = app.open("MovieDetails.fxml", "RQS - Movie details");
            controller.setMovie(selected);
        } catch(IOException e) {
            throw new RuntimeException(e);
        }
    }

    private void onSearch() {
        String text = searchField.textProperty().get();
        if(text.isEmpty() || text.equals(lastSearch)) {
            return;
        }
        lastSearch = text;

        if(task != null && task.isRunning()) {
            task.cancel();
            while(task.isRunning()) {
                try {
                    TimeUnit.MILLISECONDS.sleep(10);
                } catch(InterruptedException e) {
                    break;
                }
            }
            loadingImage.setVisible(false);
        }

        Map<String, List<String>> query = parser.parse(text);
        if(query.isEmpty()) {
            return;
        }

        updateCount(0);

        task = new SearchTask(app, query);
        searchResultTable.setItems(task.fetchedValuesProperty());
        task.valueProperty().addListener((obs, o, n) -> updateCount(n));
        task.setOnSucceeded(e -> loadingImage.setVisible(false));
        task.setOnFailed(e -> {
            Throwable throwable = e.getSource().getException();
            throwable.printStackTrace();

            // Flash the input box red so they know without bothering them too much
            loadingImage.setVisible(false);
            searchField.getStyleClass().add("error");
            Task<Void> task = new Task<Void>() {
                @Override
                protected Void call() throws Exception {
                    TimeUnit.MILLISECONDS.sleep(500);
                    return null;
                }
            };
            task.setOnSucceeded(bleh -> searchField.getStyleClass().remove("error"));
            app.getThreadPool().execute(task);
        });
        loadingImage.setVisible(true);
        app.getThreadPool().execute(task);
    }

    private void updateCount(int count) {
        countText.setText(String.valueOf(count) + " result" + (count > 1 ? 's' : ""));
    }

    private static String generatePlaceholders(int count) {
        return IntStream.range(0, count).mapToObj(i -> "?").collect(Collectors.joining(", "));
    }

    private void onHelp() {
        Alert alert = app.alert(Alert.AlertType.INFORMATION, "Search movies by title.\n" +
            "You can provide a more complex filter by using these specific keywords:\n" +
            "+ id\n" +
            "+ title\n" +
            "+ actor\n" +
            "+ director\n" +
            "+ before (year)\n" +
            "+ after (year)\n" +
            "+ during (year)\n\n" +
            "Example: actor:\"Bob Marley\" title:rx before:2013\n", this);
        alert.setTitle("Search query syntax - RQS");
        alert.setHeaderText("Search query syntax");
        //alert.getDialogPane().setExpanded(true);
        alert.showAndWait();
    }

    private static class SearchTask extends FetchTask<Movie> {

        public SearchTask(SearchApplication app, Map<String, List<String>> query) {
            super(app.getConnection(), () -> buildQuery(app.getConnection(), query), rs -> new Movie(
                ResultSetExtractor.getInt(rs, "movie_id").getAsInt(),
                ResultSetExtractor.getString(rs, "movie_title").get(),
                ResultSetExtractor.getString(rs, "movie_original_title").get(),
                ResultSetExtractor.getDate(rs, "movie_release_date").map(Date::toLocalDate).orElse(null),
                ResultSetExtractor.getString(rs, "status_name").orElse("(empty)"),
                ResultSetExtractor.getDouble(rs, "movie_vote_avg").getAsDouble(),
                ResultSetExtractor.getInt(rs, "movie_vote_count").getAsInt(),
                ResultSetExtractor.getInt(rs, "movie_runtime").orElse(0),
                ResultSetExtractor.getBytes(rs, "image").orElseGet(app::getEmptyImage),
                ResultSetExtractor.getInt(rs, "movie_budget").getAsInt(),
                ResultSetExtractor.getInt(rs, "movie_revenue").getAsInt(),
                ResultSetExtractor.getString(rs, "movie_homepage").orElse("(empty)"),
                ResultSetExtractor.getString(rs, "movie_tagline").orElse("(empty)"),
                ResultSetExtractor.getString(rs, "movie_overview").orElse("(empty)")
            ));
        }

        private static CallableStatement buildQuery(SwappableConnection connection, Map<String, List<String>> query) throws SQLException {
            if(query.containsKey("id")) {
                CallableStatement stmt = connection.prepareCall("{ ? = call search.search(p_id => ?) }");
                stmt.registerOutParameter(1, OracleTypes.CURSOR);
                stmt.setInt(2, Integer.parseInt(query.get("id").get(0)));
                return stmt;
            }

            List<String> title = query.getOrDefault("title", Collections.emptyList());
            List<String> actors = query.getOrDefault("actor", Collections.emptyList());
            List<String> directors = query.getOrDefault("director", Collections.emptyList());
            List<String> before = query.getOrDefault("before", Collections.emptyList());
            List<String> after = query.getOrDefault("after", Collections.emptyList());
            List<String> during = query.getOrDefault("during", Collections.emptyList());
            int min = -1, max = -1, exact = -1;

            // Generate query
            StringBuilder sb = new StringBuilder("{ ? = call search.search(");
            if(!title.isEmpty()) {
                sb.append("p_title => ?, ");
            }
            if(!actors.isEmpty()) {
                sb
                    .append("p_actors => varchar2_t(")
                    .append(generatePlaceholders(query.get("actor").size()))
                    .append("), ");
            }
            if(!directors.isEmpty()) {
                sb
                    .append("p_directors => varchar2_t(")
                    .append(generatePlaceholders(query.get("director").size()))
                    .append("), ");
            }
            if(!during.isEmpty()) {
                if(during.size() != 1) {
                    throw new IllegalArgumentException("More than one value for during is dumb");
                }
                sb.append("p_during => ?, ");
                exact = Integer.parseInt(during.get(0));
            }
            if(!before.isEmpty()) {
                min = before.stream().mapToInt(Integer::parseInt).min().getAsInt();
                if(exact > min) {
                    throw new IllegalArgumentException("Exact year after before condition");
                }
                sb.append("p_before => ?, ");
            }
            if(!after.isEmpty()) {
                max = after.stream().mapToInt(Integer::parseInt).max().getAsInt();
                if(exact != -1 && max > exact) {
                    throw new IllegalArgumentException("Exact year before after condition");
                }
                if(min != -1 && max > min) {
                    throw new IllegalArgumentException("Can't have year before " + min + "and after " + max);
                }
                sb.append("p_after => ?, ");
            }
            sb.setLength(sb.length() - 2); // Removes trailing ", "
            sb.append(") }");
            System.out.println(sb);

            CallableStatement cs = connection.prepareCall(sb.toString());

            // Bind stuff
            int i = 0;
            cs.registerOutParameter(++i, OracleTypes.CURSOR);
            if(!title.isEmpty()) {
                cs.setString(++i, String.join(" ", title));
            }
            if(!actors.isEmpty()) {
                for(String actor : actors) {
                    cs.setString(++i, actor);
                }
            }
            if(!directors.isEmpty()) {
                for(String director : directors) {
                    cs.setString(++i, director);
                }
            }
            if(!before.isEmpty()) {
                cs.setInt(++i, min);
            }
            if(!after.isEmpty()) {
                cs.setInt(++i, max);
            }
            if(!during.isEmpty()) {
                cs.setInt(++i, Integer.parseInt(during.get(0)));
            }

            return cs;
        }

    }

}
