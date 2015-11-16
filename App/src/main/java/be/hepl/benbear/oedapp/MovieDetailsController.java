package be.hepl.benbear.oedapp;

import javafx.fxml.FXML;
import javafx.scene.control.Label;
import javafx.scene.control.TableView;
import javafx.scene.image.ImageView;

import java.text.NumberFormat;
import java.time.LocalDate;
import java.util.Locale;

public class MovieDetailsController {

    private static final NumberFormat MONEY = NumberFormat.getCurrencyInstance(Locale.US);

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
    @FXML private TableView actorsTable;
    @FXML private TableView directorsTable;

    public MovieDetailsController(SearchApplication app) {
        this.app = app;
    }

    public void setMovie(Movie movie) {
        movieImage.setImage(movie.getImage());
        originalTitleText.setText(movie.getOriginalTitle());
        runtimeText.setText(String.valueOf(movie.getRuntime()));
        statusText.setText(movie.getStatus());
        revenueText.setText(MONEY.format(movie.getRevenue()));
        budgetText.setText(MONEY.format(movie.getBudget()));
        //languageText.setText(movie.getL);
        LocalDate date = movie.getReleaseDate();
        titleText.setText(movie.getTitle() + " (" + (date == null ? "unknown" : date.getYear()) + ')');
        overviewText.setText(movie.getOverview());
        votesText.setText(String.valueOf(movie.getVoteAvg()) + " / 10 (" + movie.getVoteCount() + ')');
        taglineText.setText(movie.getTagline());
        // TODO actors
        // TODO directors
    }

}
