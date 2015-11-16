package be.hepl.benbear.oedapp;

import be.hepl.benbear.oedapp.jdbc.ResultSetExtractor;
import be.hepl.benbear.oedapp.parser.SearchParser;
import javafx.beans.property.ReadOnlyObjectWrapper;
import javafx.collections.ObservableList;
import javafx.concurrent.Task;
import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.control.*;
import javafx.scene.image.ImageView;
import javafx.scene.input.KeyCode;
import javafx.scene.input.MouseButton;
import oracle.jdbc.OracleTypes;

import java.io.IOException;
import java.net.URL;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.Date;
import java.sql.ResultSet;
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
    private String lastSearch = "";
    private Task<Movie> task;
    private int count = 0;

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
                } catch(InterruptedException e) {}
            }
        }

        Map<String, List<String>> query = parser.parse(text);
        ObservableList<Movie> movies = searchResultTable.itemsProperty().getValue();
        movies.clear();
        count = 0;
        updateCount();

        task = new SearchTask(query);
        task.valueProperty().addListener((obs, o, n) -> {
            if(n == null) {
                return;
            }
            movies.add(n);
            updateCount();
        });
        task.setOnFailed(e -> {
            Throwable throwable = e.getSource().getException();
            throwable.printStackTrace();

            // Flash the input box read so they know without bothering them too much
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
        app.getThreadPool().execute(task);
    }

    private void updateCount() {
        countText.setText(String.valueOf(count) + " result" + (count > 1 ? 's' : ""));
    }

    private String generatePlaceholders(int count) {
        return IntStream.range(0, count).mapToObj(i -> "?").collect(Collectors.joining(", "));
    }

    private void onHelp() {
        Dialog<Void> dialog = new Dialog<>();
        dialog.setContentText("Here be the syntax of the query");
        dialog.setOnCloseRequest(e -> dialog.close());
        dialog.getDialogPane().getButtonTypes().add(new ButtonType("OK", ButtonBar.ButtonData.OK_DONE));
        dialog.show();
    }

    private class SearchTask extends Task<Movie> {

        private final Map<String, List<String>> query;

        public SearchTask(Map<String, List<String>> query) {
            this.query = query;
        }

        @Override
        protected Movie call() throws Exception {
            try(CallableStatement cs = buildQuery(app.getConnection(), query)) {
                cs.execute();

                try(ResultSet rs = (ResultSet) cs.getObject(1)) {
                    while(rs.next()) {
                        if(isCancelled()) {
                            break;
                        }

                        updateValue(new Movie(
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
                        ++count;
                    }
                    return null;
                }
            }
        }

        private CallableStatement buildQuery(Connection connection, Map<String, List<String>> query) throws SQLException {
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
            if(!before.isEmpty() || !after.isEmpty() || !during.isEmpty()) {
                int count = before.size() + after.size() + during.size();
                sb
                    .append("p_years => number_t(")
                    .append(generatePlaceholders(count))
                    .append("), ")
                    .append("p_years_comparisons => varchar2_t(")
                    .append(generatePlaceholders(count))
                    .append("), ");
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
            if(!before.isEmpty() || !after.isEmpty() || !during.isEmpty()) {
                for(String bef : before) {
                    cs.setInt(++i, Integer.parseInt(bef));
                }
                for(String aft : after) {
                    cs.setInt(++i, Integer.parseInt(aft));
                }
                for(String dur : during) {
                    cs.setInt(++i, Integer.parseInt(dur));
                }

                for(String s : before) {
                    cs.setString(++i, "<");
                }
                for(String s : after) {
                    cs.setString(++i, ">");
                }
                for(String s : during) {
                    cs.setString(++i, "=");
                }
            }

            return cs;
        }

    }

}
