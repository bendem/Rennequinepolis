package be.hepl.benbear.oedapp;

import be.hepl.benbear.oedapp.jdbc.ResultSetExtractor;
import javafx.beans.property.ReadOnlyObjectWrapper;
import javafx.concurrent.Task;
import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.control.Label;
import javafx.scene.control.TableColumn;
import javafx.scene.control.TableView;
import javafx.scene.image.ImageView;
import oracle.jdbc.OracleTypes;

import java.net.URL;
import java.sql.CallableStatement;
import java.sql.ResultSet;
import java.text.NumberFormat;
import java.time.LocalDate;
import java.util.Locale;
import java.util.ResourceBundle;

public class MovieDetailsController implements Initializable {

    private static final NumberFormat MONEY;
    static {
        NumberFormat money = NumberFormat.getCurrencyInstance(Locale.US);
        money.setMaximumFractionDigits(0);
        MONEY = money;
    }

    private final SearchApplication app;
    @FXML private ImageView movieImage;
    @FXML private Label originalTitleText;
    @FXML private Label runtimeText;
    @FXML private Label statusText;
    @FXML private Label revenueText;
    @FXML private Label budgetText;
    @FXML private Label languageText;
    @FXML private Label titleText;
    @FXML private Label overviewText;
    @FXML private Label votesText;
    @FXML private Label taglineText;
    @FXML private TableView<Person> actorsTable;
    @FXML private TableColumn<Person, ImageView> actorImageColumn;
    @FXML private TableColumn<Person, String> actorNameColumn;
    @FXML private TableView<Person> directorsTable;
    @FXML private TableColumn<Person, ImageView> directorImageColumn;
    @FXML private TableColumn<Person, String> directorNameColumn;
    @FXML private TableView reviewsTable;
    @FXML private TableColumn<Review, String> reviewUsernameColumn;
    @FXML private TableColumn<Review, Integer> reviewRatingColumn;
    @FXML private TableColumn<Review, LocalDate> reviewDateColumn;
    @FXML private TableColumn<Review, String> reviewContentColumn;

    public MovieDetailsController(SearchApplication app) {
        this.app = app;
    }

    @Override
    public void initialize(URL location, ResourceBundle resources) {
        actorImageColumn.setCellValueFactory(feature ->
            new ReadOnlyObjectWrapper<>(new ImageView(feature.getValue().getImage())));
        actorNameColumn.setCellValueFactory(feature ->
            new ReadOnlyObjectWrapper<>(feature.getValue().getName()));

        directorImageColumn.setCellValueFactory(feature ->
            new ReadOnlyObjectWrapper<>(new ImageView(feature.getValue().getImage())));
        directorNameColumn.setCellValueFactory(feature ->
            new ReadOnlyObjectWrapper<>(feature.getValue().getName()));

        reviewUsernameColumn.setCellValueFactory(feature ->
            new ReadOnlyObjectWrapper<>(feature.getValue().getUsername()));
        reviewRatingColumn.setCellValueFactory(feature ->
            new ReadOnlyObjectWrapper<>(feature.getValue().getRating()));
        reviewDateColumn.setCellValueFactory(feature ->
            new ReadOnlyObjectWrapper<>(feature.getValue().getDate()));
        reviewContentColumn.setCellValueFactory(feature ->
            new ReadOnlyObjectWrapper<>(feature.getValue().getContent()));
    }

    public void setMovie(Movie movie) {
        movieImage.setImage(movie.getImage());
        originalTitleText.setText(movie.getOriginalTitle());
        runtimeText.setText(String.valueOf(movie.getRuntime()));
        statusText.setText(movie.getStatus());
        revenueText.setText(MONEY.format(movie.getRevenue()));
        budgetText.setText(MONEY.format(movie.getBudget()));
        //languageText.setText(movie.getL); TODO Languages
        LocalDate date = movie.getReleaseDate();
        titleText.setText(movie.getTitle() + " (" + (date == null ? "unknown" : date.getYear()) + ')');
        overviewText.setText(movie.getOverview());
        votesText.setText(String.valueOf(movie.getVoteAvg()) + " / 10 (" + movie.getVoteCount() + ')');
        taglineText.setText(movie.getTagline());

        Task<Person> actorsTask = new PeopleTask(movie.getId(), "actors");
        actorsTask.valueProperty().addListener((obs, o, n) -> {
            if(n != null) {
                actorsTable.getItems().add(n);
            }
        });
        actorsTask.setOnFailed(e -> e.getSource().getException().printStackTrace());
        app.getThreadPool().execute(actorsTask);

        Task<Person> directorsTask = new PeopleTask(movie.getId(), "directors");
        directorsTask.valueProperty().addListener((obs, o, n) -> {
            if(n != null) {
                directorsTable.getItems().add(n);
            }
        });
        directorsTask.setOnFailed(e -> e.getSource().getException().printStackTrace());
        app.getThreadPool().execute(directorsTask);
        // TODO reviews
    }

    private class PeopleTask extends Task<Person> {

        private final int movieId;
        private final String kind;

        public PeopleTask(int movieId, String kind) {
            this.movieId = movieId;
            this.kind = kind;
        }

        @Override
        protected Person call() throws Exception {
            try(CallableStatement cs = app.getConnection().prepareCall("{ ? = call search.get_" + kind + "(?) }")) {
                cs.registerOutParameter(1, OracleTypes.CURSOR);
                cs.setInt(2, movieId);
                cs.execute();
                try(ResultSet rs = (ResultSet) cs.getObject(1)) {
                    while(rs.next()) {
                        updateValue(new Person(
                            rs.getInt("person_id"),
                            rs.getString("person_name"),
                            ResultSetExtractor.getBytes(rs, "image").orElseGet(app::getEmptyImage)
                        ));
                    }
                }
            }
            return null;
        }

    }

}
