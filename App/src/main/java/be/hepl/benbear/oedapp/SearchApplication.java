package be.hepl.benbear.oedapp;

import javafx.application.Application;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.stage.Stage;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.InvocationTargetException;
import java.net.URL;
import java.sql.Connection;
import java.sql.DriverManager;
import java.util.Objects;
import java.util.concurrent.Executor;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class SearchApplication extends Application {

    private static byte[] EMPTY_IMAGE;

    private final ExecutorService threadPool = Executors.newFixedThreadPool(2);
    private Connection connection;

    public static void main(String[] args) {
        launch(args);
    }

    @Override
    public void start(Stage stage) throws IOException {
        open("SearchApplication.fxml", "RQS - Search");
    }

    public <T> T open(String fxml, String title) throws IOException {
        FXMLLoader loader = new FXMLLoader(getResource(fxml));

        loader.setControllerFactory(clazz -> {
            try {
                return clazz.getConstructor(SearchApplication.class).newInstance(this);
            } catch(InstantiationException | IllegalAccessException
                | NoSuchMethodException | InvocationTargetException e) {
                throw new RuntimeException("Could not instantiate controller for " + clazz, e);
            }
        });

        Parent app = loader.load();
        Stage stage = new Stage();
        app.getStylesheets().add(getResource("style.css").toExternalForm());
        stage.setTitle(title);
        stage.setScene(new Scene(app));
        stage.show();
        return loader.getController();
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
        threadPool.shutdown();
    }

    public Connection getConnection() {
        return connection;
    }

    private URL getResource(String name) {
        return Objects.requireNonNull(getClass().getClassLoader().getResource(name), "Resource not found: " + name);
    }

    private InputStream getResourceStream(String name) {
        return Objects.requireNonNull(getClass().getClassLoader().getResourceAsStream(name), "Resource not found: " + name);
    }

    public byte[] getEmptyImage() {
        if(EMPTY_IMAGE == null) {
            synchronized(SearchApplication.class) {
                if(EMPTY_IMAGE == null) {
                    ByteArrayOutputStream out = new ByteArrayOutputStream();
                    byte[] buffer = new byte[255];
                    InputStream resource = getResourceStream("empty.jpg");
                    try {
                        while(resource.read(buffer) > 0) {
                            out.write(buffer);
                        }
                    } catch(IOException e) {
                        throw new RuntimeException(e);
                    }
                    EMPTY_IMAGE = out.toByteArray();
                }
            }
        }
        return EMPTY_IMAGE;
    }

    public Executor getThreadPool() {
        return threadPool;
    }

}
