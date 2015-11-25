package be.hepl.benbear.oedapp;

import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.control.Button;
import javafx.scene.control.TextArea;

import java.net.URL;
import java.time.LocalDate;
import java.util.ResourceBundle;

public class ReviewController implements Initializable {

    private final SearchApplication app;
    private Review oldReview = null;
    private Review review = null;

    @FXML private Button okButton;
    @FXML private Button cancelButton;
    @FXML private TextArea reviewTextArea;


    public ReviewController(SearchApplication app) {
        this.app = app;
    }

    @Override
    public void initialize(URL location, ResourceBundle resources) {
        okButton.setOnAction(e -> onOK());
    }

    private void onOK() {
        this.review.setDate(LocalDate.now());
        //this.review.setRating();
        this.review.setContent(reviewTextArea.getText());

        app.getConnection().
    }

    public void setReview(Review review) {
        this.oldReview = review;
        this.review = review;
    }
}
