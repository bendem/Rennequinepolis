package be.hepl.benbear.oedapp;

import be.hepl.benbear.oedapp.jdbc.ExceptionUtil;
import javafx.application.Platform;
import javafx.beans.value.ChangeListener;
import javafx.event.ActionEvent;
import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.control.Alert;
import javafx.scene.control.Button;
import javafx.scene.control.PasswordField;
import javafx.scene.control.TextArea;
import javafx.scene.control.TextField;
import javafx.scene.layout.Background;
import javafx.scene.layout.BackgroundFill;
import javafx.scene.layout.StackPane;
import javafx.scene.layout.VBox;
import javafx.scene.paint.Color;

import java.net.URL;
import java.sql.SQLException;
import java.util.ResourceBundle;
import java.util.function.Predicate;

public class ReviewController implements Initializable {

    // Provides a transparent background while still preventing to click through it
    private static final Background EMPTY_BACKGROUND = new Background(new BackgroundFill(Color.TRANSPARENT, null, null));
    private static final Predicate<String> HAS_SPACES_ONLY = s -> s.isEmpty()
        || s.charAt(0) == ' '
        || s.charAt(s.length() - 1) == ' ';

    private final SearchApplication app;
    private MovieDetailsController movieDetailsController;
    @FXML private StackPane stackPane;
    @FXML private VBox reviewVBox;
    @FXML private VBox loginVBox;
    @FXML private TextField ratingField;
    @FXML private TextArea reviewField;
    @FXML private TextField usernameField;
    @FXML private PasswordField passwordField;
    @FXML private Button loginButton;
    @FXML private Button reviewButton;

    public ReviewController(SearchApplication app) {
        this.app = app;
    }

    @Override
    public void initialize(URL location, ResourceBundle resources) {
        reviewVBox.setBackground(EMPTY_BACKGROUND);
        loginVBox.setBackground(EMPTY_BACKGROUND);
        if(app.getUser() == null) {
            swapPanes(true);
        }

        loginButton.setOnAction(this::onLogin);
        reviewButton.setOnAction(this::onReview);

        Inputs.error(usernameField, HAS_SPACES_ONLY);
        Inputs.error(passwordField, String::isEmpty);

        Inputs.error(ratingField, s -> !s.matches("[0-9]+"));

        ChangeListener<String> loginDisable = Inputs.disable(loginButton,
            () -> HAS_SPACES_ONLY.test(usernameField.getText()),
            () -> passwordField.getText().isEmpty());
        usernameField.textProperty().addListener(loginDisable);
        passwordField.textProperty().addListener(loginDisable);

        ChangeListener<String> reviewDisable = Inputs.disable(reviewButton,
            () -> !ratingField.getText().matches("[0-9]+"));
        ratingField.textProperty().addListener(reviewDisable);

        Inputs.integer(ratingField, 0, 10);
    }

    private void swapPanes(boolean loginAbove) {
        if(loginAbove) {
            loginVBox.toBack(); // TODO Check this works
            reviewVBox.setOpacity(0);
            loginVBox.setOpacity(1);
        } else {
            reviewVBox.toBack(); // TODO Check this works
            loginVBox.setOpacity(0);
            reviewVBox.setOpacity(1);
        }

        loginButton.setDefaultButton(loginAbove);
        reviewButton.setDefaultButton(!loginAbove);
        reviewVBox.setDisable(loginAbove);
        loginVBox.setDisable(!loginAbove);
    }

    private void onLogin(ActionEvent actionEvent) {
        String username = usernameField.getText().trim();

        // TODO This should be off the main thread
        // FIXME This should call a procedure abstracting backup_flag away!
        app.getConnection().preparedStatement("select * from users where username = ? and backup_flag <> 2",
            stmt -> stmt.setString(1, username),
            rs -> {
                if(!rs.next()) {
                    app.alert(Alert.AlertType.ERROR, "Invalid username or password", this).showAndWait();
                    return;
                }

                String dbPassword = rs.getString("password");
                if(passwordField.getText().equals(dbPassword)) {
                    app.connectUser(username);
                    swapPanes(false);
                }
            },
            e -> {
                e.printStackTrace();
                app.alert(
                    Alert.AlertType.ERROR,
                    "An error happened: " + e.getMessage(),
                    movieDetailsController
                ).showAndWait();
            });
    }

    private void onReview(ActionEvent actionEvent) {
        // TODO This should be off the main thread
        app.getConnection().preparedCall("{ call management.add_review(?, ?, ?, ?) }",
            stmt -> {
                stmt.setString(1, app.getUser());
                stmt.setInt(2, movieDetailsController.getMovie().getId());
                stmt.setInt(3, Integer.parseInt(ratingField.getText().trim()));
                stmt.setString(4, reviewField.getText().trim());
                stmt.execute();
                app.getConnection().commit();

                Platform.runLater(() -> {
                    app.getStage(this).close();
                    movieDetailsController.loadReviews(1);
                    app.alert(Alert.AlertType.INFORMATION, "Review added", movieDetailsController).show();
                });
            },
            e -> {
                try {
                    app.getConnection().rollback();
                } catch(SQLException ignored) {}
                e.printStackTrace();
                Platform.runLater(() -> {
                    app.alert(
                        Alert.AlertType.ERROR,
                        "An error happened: " + ExceptionUtil.extractMessage(e),
                        this
                    ).showAndWait();
                });
            });
    }

    public void setMovieDetailsController(MovieDetailsController movieDetailsController) {
        this.movieDetailsController = movieDetailsController;
    }

}
