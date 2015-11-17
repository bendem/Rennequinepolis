package be.hepl.benbear.oedapp;

import be.hepl.benbear.oedapp.jdbc.ResultSetExtractor;
import javafx.application.Platform;
import javafx.beans.property.ReadOnlyObjectWrapper;
import javafx.beans.value.ObservableValue;
import javafx.concurrent.Task;
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
    private int reviewsPage = 1;

    public MovieDetailsController(SearchApplication app) {
        this.app = app;
    }

    @Override
    public void initialize(URL location, ResourceBundle resources) {
        Callback<TableColumn.CellDataFeatures<Person, ImageView>, ObservableValue<ImageView>> imageCellValueFactory = feature -> {
            ImageView view = new ImageView(feature.getValue().getImage());
            view.setPreserveRatio(true);
            view.setFitHeight(150);
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

    private void loadReviews(int page) {
        if(page != 1) {
            previousReviewsButton.setDisable(false);
        }
        reviewsTable.getItems().clear();
        Task<Review> task = new ReviewTask(page);
        task.valueProperty().addListener((obs, o, n) -> {
            if(n != null) {
                reviewsTable.getItems().add(n);
            }
        });
        task.setOnFailed(e -> e.getSource().getException().printStackTrace());
        app.getThreadPool().execute(task);
    }

    public void setMovie(Movie movie) {
        this.movie = movie;
        movieImage.setImage(movie.getImage());
        originalTitleText.setText(movie.getOriginalTitle());
        runtimeText.setText(String.valueOf(movie.getRuntime()));
        statusText.setText(movie.getStatus());
        revenueText.setText(MONEY.format(movie.getRevenue()));
        budgetText.setText(MONEY.format(movie.getBudget()));
        Task<Set<String>> task = new LanguageTask();
        task.valueProperty().addListener((obs, o, n) -> {
            if(!n.isEmpty()) {
                languageText.setText(String.join(", ", n));
            }
        });
        app.getThreadPool().execute(task);
        LocalDate date = movie.getReleaseDate();
        titleText.setText(movie.getTitle() + " (" + (date == null ? "unknown" : date.getYear()) + ')');
        votesText.setText(String.valueOf(movie.getVoteAvg()) + " / 10 (" + movie.getVoteCount() + ')');
        overviewText.setText(movie.getOverview());
        taglineText.setText(movie.getTagline());
        homepageLink.setText(movie.getHomepage());
        if(!movie.getHomepage().equals("(empty)")) {
            homepageLink.setOnAction(e -> app.getHostServices().showDocument(movie.getHomepage()));
        }

        Task<Person> actorsTask = new PeopleTask("actors");
        actorsTask.valueProperty().addListener((obs, o, n) -> {
            if(n != null) {
                actorsTable.getItems().add(n);
            }
        });
        actorsTask.setOnFailed(e -> e.getSource().getException().printStackTrace());
        app.getThreadPool().execute(actorsTask);

        Task<Person> directorsTask = new PeopleTask("directors");
        directorsTask.valueProperty().addListener((obs, o, n) -> {
            if(n != null) {
                directorsTable.getItems().add(n);
            }
        });
        directorsTask.setOnFailed(e -> e.getSource().getException().printStackTrace());
        app.getThreadPool().execute(directorsTask);

        loadReviews(1);
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

    private class PeopleTask extends Task<Person> {

        private final String kind;

        public PeopleTask(String kind) {
            this.kind = kind;
        }

        @Override
        protected Person call() throws Exception {
            try(CallableStatement cs = app.getConnection().prepareCall("{ ? = call search.get_" + kind + "(?) }")) {
                cs.registerOutParameter(1, OracleTypes.CURSOR);
                cs.setInt(2, movie.getId());
                cs.execute();
                int count = 0;
                try(ResultSet rs = (ResultSet) cs.getObject(1)) {
                    while(rs.next()) {
                        if(isCancelled()) {
                            break;
                        }

                        updateValue(new Person(
                            rs.getInt("person_id"),
                            rs.getString("person_name"),
                            ResultSetExtractor.getBytes(rs, "image").orElseGet(app::getEmptyImage)
                        ));
                        ++count;
                    }
                }

                int countFinal = count;
                Platform.runLater(() -> nextReviewsButton.setDisable(countFinal < 5));
            }
            return null;
        }

    }

    private class ReviewTask extends Task<Review> {

        private final int page;

        public ReviewTask(int page) {
            this.page = page;
        }

        @Override
        protected Review call() throws Exception {
            try(CallableStatement cs = app.getConnection().prepareCall("{ ? = call search.get_reviews(?, ?) }")) {
                cs.registerOutParameter(1, OracleTypes.CURSOR);
                cs.setInt(2, movie.getId());
                cs.setInt(3, page);
                cs.execute();
                try(ResultSet rs = (ResultSet) cs.getObject(1)) {
                    while(rs.next()) {
                        if(isCancelled()) {
                            break;
                        }

                        updateValue(new Review(
                            rs.getString("username"),
                            rs.getInt("rating"),
                            rs.getDate("creation_date").toLocalDate(),
                            rs.getString("content")
                        ));
                    }
                }
            }
            return null;
        }

    }

}
