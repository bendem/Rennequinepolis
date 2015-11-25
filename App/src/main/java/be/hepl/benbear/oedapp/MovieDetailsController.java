package be.hepl.benbear.oedapp;

import be.hepl.benbear.oedapp.jdbc.ResultSetExtractor;
import javafx.beans.property.ReadOnlyObjectWrapper;
import javafx.beans.value.ObservableValue;
import javafx.concurrent.Task;
import javafx.concurrent.WorkerStateEvent;
import javafx.event.EventHandler;
import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.control.Button;
import javafx.scene.control.Hyperlink;
import javafx.scene.control.Label;
import javafx.scene.control.TableColumn;
import javafx.scene.control.TableView;
import javafx.scene.image.ImageView;
import javafx.util.Callback;
import oracle.jdbc.OracleTypes;

import java.net.URL;
import java.sql.CallableStatement;
import java.sql.ResultSet;
import java.text.NumberFormat;
import java.time.LocalDate;
import java.util.HashSet;
import java.util.Locale;
import java.util.ResourceBundle;
import java.util.Set;

public class MovieDetailsController implements Initializable {

    private static final EventHandler<WorkerStateEvent> FAILURE_HANDLER = e -> e.getSource().getException().printStackTrace();
    private static final NumberFormat MONEY;
    static {
        NumberFormat money = NumberFormat.getCurrencyInstance(Locale.US);
        money.setMaximumFractionDigits(0);
        MONEY = money;
    }

    private final SearchApplication app;
    private Movie movie;
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
    @FXML private Hyperlink homepageLink;
    @FXML private TableView<Person> actorsTable;
    @FXML private TableColumn<Person, ImageView> actorImageColumn;
    @FXML private TableColumn<Person, String> actorNameColumn;
    @FXML private TableView<Person> directorsTable;
    @FXML private TableColumn<Person, ImageView> directorImageColumn;
    @FXML private TableColumn<Person, String> directorNameColumn;
    @FXML private TableView<Review> reviewsTable;
    @FXML private TableColumn<Review, String> reviewUsernameColumn;
    @FXML private TableColumn<Review, Integer> reviewRatingColumn;
    @FXML private TableColumn<Review, LocalDate> reviewDateColumn;
    @FXML private TableColumn<Review, String> reviewContentColumn;
    @FXML private Button previousReviewsButton;
    @FXML private Button nextReviewsButton;
    @FXML private Button reviewButton;
    private int reviewsPage = 1;

    public MovieDetailsController(SearchApplication app) {
        this.app = app;
    }

    @Override
    public void initialize(URL location, ResourceBundle resources) {
        Callback<TableColumn.CellDataFeatures<Person, ImageView>, ObservableValue<ImageView>> imageCellValueFactory = feature -> {
            ImageView view = new ImageView(feature.getValue().getImage());
            view.setPreserveRatio(true);
            view.setFitWidth(120);
            return new ReadOnlyObjectWrapper<>(view);
        };

        actorImageColumn.setCellValueFactory(imageCellValueFactory);
        actorNameColumn.setCellValueFactory(feature ->
            new ReadOnlyObjectWrapper<>(feature.getValue().getName()));

        directorImageColumn.setCellValueFactory(imageCellValueFactory);
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

        previousReviewsButton.setOnAction(e -> {
            if(reviewsPage != 1) {
                loadReviews(--reviewsPage);
            }
        });
        nextReviewsButton.setOnAction(e -> loadReviews(++reviewsPage));
    }

    public void setMovie(Movie movie) {
        this.movie = movie;

        movieImage.setImage(movie.getImage());
        originalTitleText.setText(movie.getOriginalTitle());
        runtimeText.setText(String.valueOf(movie.getRuntime()));
        statusText.setText(movie.getStatus());
        revenueText.setText(MONEY.format(movie.getRevenue()));
        budgetText.setText(MONEY.format(movie.getBudget()));
        LocalDate date = movie.getReleaseDate();
        titleText.setText(movie.getTitle() + " (" + (date == null ? "unknown" : date.getYear()) + ')');
        votesText.setText(String.valueOf(movie.getVoteAvg()) + " / 10 (" + movie.getVoteCount() + ')');
        overviewText.setText(movie.getOverview());
        taglineText.setText(movie.getTagline());
        homepageLink.setText(movie.getHomepage());
        if(!movie.getHomepage().equals("(empty)")) {
            // FIXME This doesn't seem to open the default browser (at least not accurately)
            homepageLink.setOnAction(e -> app.getHostServices().showDocument(movie.getHomepage()));
        }

        Task<Set<String>> languagesTask = new LanguageTask();
        languagesTask.valueProperty().addListener((obs, o, n) -> {
            if(!n.isEmpty()) {
                languageText.setText(String.join(", ", n));
            }
        });
        languagesTask.setOnFailed(FAILURE_HANDLER);
        app.getThreadPool().execute(languagesTask);

        FetchTask<Person> actorsTask = getPersonFetchTask("actors");
        actorsTable.setItems(actorsTask.fetchedValuesProperty());
        actorsTask.setOnFailed(FAILURE_HANDLER);
        app.getThreadPool().execute(actorsTask);

        FetchTask<Person> directorsTask = getPersonFetchTask("directors");
        directorsTable.setItems(directorsTask.fetchedValuesProperty());
        directorsTask.setOnFailed(FAILURE_HANDLER);
        app.getThreadPool().execute(directorsTask);

        loadReviews(1);
    }

    private FetchTask<Person> getPersonFetchTask(String kind) {
        return new FetchTask<>(() -> {
            CallableStatement cs = app.getConnection().prepareCall("{ ? = call search.get_" + kind + "(?) }");
            cs.registerOutParameter(1, OracleTypes.CURSOR);
            cs.setInt(2, movie.getId());
            cs.execute();
            return cs;
        }, rs -> new Person(
            rs.getInt("person_id"),
            rs.getString("person_name"),
            ResultSetExtractor.getBytes(rs, "image").orElseGet(app::getEmptyImage)
        ));
    }

    private void loadReviews(int page) {
        previousReviewsButton.setDisable(page == 1);

        FetchTask<Review> task = getReviewFetchTask(page);
        reviewsTable.setItems(task.fetchedValuesProperty());
        task.setOnFailed(FAILURE_HANDLER);
        task.valueProperty().addListener((obs, o, n) -> {
            nextReviewsButton.setDisable(n != 5);
        });
        app.getThreadPool().execute(task);
    }

    private FetchTask<Review> getReviewFetchTask(int page) {
        return new FetchTask<>(() -> {
            CallableStatement cs = app.getConnection().prepareCall("{ ? = call search.get_reviews(?, ?) }");
            cs.registerOutParameter(1, OracleTypes.CURSOR);
            cs.setInt(2, movie.getId());
            cs.setInt(3, page);
            return cs;
        }, rs -> new Review(
            rs.getString("username"),
            rs.getInt("rating"),
            rs.getDate("creation_date").toLocalDate(),
            rs.getString("content")
        ));
    }

    private class LanguageTask extends Task<Set<String>> {
        @Override
        protected Set<String> call() throws Exception {
            Set<String> set = new HashSet<>();
            try(CallableStatement cs = app.getConnection().prepareCall("{ ? = call search.get_languages(?) }")) {
                cs.registerOutParameter(1, OracleTypes.CURSOR);
                cs.setInt(2, movie.getId());
                cs.execute();
                try(ResultSet rs = (ResultSet) cs.getObject(1)) {
                    while(rs.next()) {
                        set.add(rs.getString("spoken_language_name"));
                    }
                }
            }
            return set;
        }
    }

}
