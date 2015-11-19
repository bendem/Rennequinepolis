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
    private static byte[] LOADING_IMAGE;

    public static void main(String[] args) {
        launch(args);
    }

    private final ExecutorService threadPool = Executors.newFixedThreadPool(2);
    private Stage mainStage;
    private Connection connection;

    @Override
    public void start(Stage stage) throws IOException {
        open("SearchApplication.fxml", "RQS - Search", true);
    }

    public <T> T open(String fxml, String title) throws IOException {
        return open(fxml, title, false);
    }

    private <T> T open(String fxml, String title, boolean main) throws IOException {
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
        if(main) {
            this.mainStage = stage;
        } else {
            stage.initOwner(mainStage);
        }
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

    public Stage getMainStage() {
        return mainStage;
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

    private byte[] getResourceBytes(String name) {
        byte[] buffer = new byte[255];
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        int read;
        try(InputStream resource = getResourceStream(name)) {
            while((read = resource.read(buffer)) > 0) {
                out.write(buffer, 0, read);
            }
        } catch(IOException e) {
            throw new RuntimeException(e);
        }
        return out.toByteArray();
    }

    public byte[] getEmptyImage() {
        if(EMPTY_IMAGE == null) {
            synchronized(SearchApplication.class) {
                if(EMPTY_IMAGE == null) {
                    EMPTY_IMAGE = getResourceBytes("empty.jpg");
                }
            }
        }
        return EMPTY_IMAGE;
    }

    public byte[] getLoadingImage() {
        if(LOADING_IMAGE == null) {
            synchronized(SearchApplication.class) {
                if(LOADING_IMAGE == null) {
                    LOADING_IMAGE = getResourceBytes("loading.png");
                }
            }
        }
        return LOADING_IMAGE;
    }

    public Executor getThreadPool() {
        return threadPool;
    }
}
