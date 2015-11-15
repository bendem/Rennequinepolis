package be.hepl.benbear.oedapp;

import javafx.application.Application;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.stage.Stage;

import java.io.IOException;
import java.lang.reflect.InvocationTargetException;
import java.net.URL;
import java.sql.Connection;
import java.sql.DriverManager;
import java.util.Objects;

public class SearchApplication extends Application {

    private Connection connection;

    public static void main(String[] args) {
        launch(args);
    }

    @Override
    public void start(Stage stage) throws IOException {
        FXMLLoader loader = new FXMLLoader(getResource("SearchApplication.fxml"));

        loader.setControllerFactory(clazz -> {
            try {
                return clazz.getConstructor(SearchApplication.class).newInstance(this);
            } catch(InstantiationException | IllegalAccessException
                | NoSuchMethodException | InvocationTargetException e) {
                throw new RuntimeException("Could not instantiate controller for " + clazz, e);
            }
        });

        Parent app = loader.load();
        app.getStylesheets().add(getResource("style.css").toExternalForm());
        stage.setTitle("RQS Search");
        stage.setScene(new Scene(app));
        stage.show();
    }

    @Override
    public void init() throws Exception {
        Class.forName("oracle.jdbc.driver.OracleDriver");
        // FIXME Once again, pwd in code :/
        // TODO The connection is supposed to switch to cbb when cb dies
        connection = DriverManager.getConnection("jdbc:oracle:thin:@178.32.41.4:8080:xe", "cb", "cb_bendemiscrazy");
    }

    @Override
    public void stop() throws Exception {
        if(!connection.isClosed()) {
            System.out.println("Closing connection");
            connection.close();
        }
    }

    public Connection getConnection() {
        return connection;
    }

    private URL getResource(String name) {
        return Objects.requireNonNull(getClass().getClassLoader().getResource(name), "Resource not found: " + name);
    }

}
