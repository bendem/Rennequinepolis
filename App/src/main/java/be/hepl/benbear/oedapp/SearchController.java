package be.hepl.benbear.oedapp;

import be.hepl.benbear.oedapp.parser.SearchParser;
import javafx.beans.property.ReadOnlyObjectWrapper;
import javafx.collections.ObservableList;
import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.control.*;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import oracle.jdbc.OracleTypes;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.lang.reflect.Modifier;
import java.net.URL;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.Date;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.SQLTransientException;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.ResourceBundle;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

public class SearchController implements Initializable {

    private final SearchApplication app;
    private final SearchParser parser;
    @FXML private TextField searchField;
    @FXML private Button searchButton;
    @FXML private Button searchHelpButton;
    @FXML private TableView<Movie> searchResultTable;
    private String lastSearch = "";

    public SearchController(SearchApplication app) {
        this.app = app;
        parser = new SearchParser("title");
    }

    @Override
    public void initialize(URL location, ResourceBundle resources) {
        searchButton.setOnAction(e -> onSearch());
        searchHelpButton.setOnAction(e -> onHelp());

        List<Method> getters = Arrays.stream(Movie.class.getDeclaredMethods())
            .filter(m -> Modifier.isPublic(m.getModifiers()))
            .filter(m -> m.getName().startsWith("get"))
            .collect(Collectors.toList());

        ObservableList<TableColumn<Movie, ?>> columns = searchResultTable.getColumns();
        columns.clear();
        Collections.reverse(getters);
        for(Method method : getters) {
            TableColumn<Movie, Object> col = new TableColumn<>(method.getName().substring(3));
            col.setCellValueFactory(features -> {
                try {
                    if(col.getText().equals("Image")) {
                        return new ReadOnlyObjectWrapper<>(new ImageView((Image) method.invoke(features.getValue())));
                    }
                    return new ReadOnlyObjectWrapper<>(method.invoke(features.getValue()));
                } catch(IllegalAccessException | InvocationTargetException e) {
                    throw new RuntimeException(e);
                }
            });
            columns.add(col);
        }
    }

    private void onSearch() {
        String text = searchField.textProperty().get();
        if(text.isEmpty() || text.equals(lastSearch)) {
            return;
        }
        searchField.setDisable(true);

        try {
            onSearchThrowing(text);
        } catch(SQLTransientException e) {
            searchField.setDisable(false);
            // TODO Try again with cbb
            throw new RuntimeException(e);
        } catch(SQLException e) {
            searchField.setDisable(false);
            // TODO Handle the exception for real
            throw new RuntimeException(e);
        }
    }

    private void onSearchThrowing(String text) throws SQLException {
        // TODO Thread this, this is horribly slow
        Map<String, List<String>> query = parser.parse(text);
        CallableStatement cs = buildQuery(app.getConnection(), query);
        cs.execute();
        ResultSet rs = (ResultSet) cs.getObject(1);
        ObservableList<Movie> movies = searchResultTable.itemsProperty().getValue();
        movies.clear();

        while(rs.next()) {
            byte[] imageBytes = rs.getBytes("image");
            if(rs.wasNull()) {
                imageBytes = app.getEmptyImage();
            }

            // FIXME There is more to it to display results
            movies.add(new Movie(
                ResultSetExtractor.getInt(rs, "movie_id").orElse(0),
                ResultSetExtractor.getString(rs, "movie_title").orElse(""),
                ResultSetExtractor.getString(rs, "movie_original_title").orElse(""),
                ResultSetExtractor.getDate(rs, "movie_release_date").map(Date::toLocalDate).orElse(null),
                ResultSetExtractor.getDouble(rs, "movie_vote_avg").orElse(0),
                ResultSetExtractor.getInt(rs, "movie_vote_count").orElse(0),
                ResultSetExtractor.getInt(rs, "movie_runtime").orElse(0),
                imageBytes,
                rs.getString("movie_overview")
            ));
        }

        searchField.setDisable(false);
    }

    private CallableStatement buildQuery(Connection connection, Map<String, List<String>> query) throws SQLException {
        StringBuilder sb = new StringBuilder("{ ? = call search.search(");

        if(query.containsKey("title")) {
            sb.append("p_title => ?, ");
        }

        if(query.containsKey("actor")) {
            sb
                .append("p_actors => varchar2_t(")
                .append(generatePlaceholders(query.get("actor").size()))
                .append("), ");
        }

        if(query.containsKey("director")) {
            sb
                .append("p_directors => varchar2_t(")
                .append(generatePlaceholders(query.get("director").size()))
                .append("), ");
        }

        // TODO Date
        sb.setLength(sb.length() - 2); // Removes trailing ", "
        sb.append(") }");
        System.out.println(sb);

        CallableStatement cs = connection.prepareCall(sb.toString());

        int i = 0;
        cs.registerOutParameter(++i, OracleTypes.CURSOR);

        if(query.containsKey("title")) {
            cs.setString(++i, query.get("title").get(0));
        }

        if(query.containsKey("actor")) {
            for(String actor : query.get("actor")) {
                cs.setString(++i, actor);
            }
        }

        if(query.containsKey("director")) {
            for(String director : query.get("director")) {
                cs.setString(++i, director);
            }
        }

        // TODO Date binding

        return cs;
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
}
