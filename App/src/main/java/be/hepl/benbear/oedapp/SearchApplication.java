package be.hepl.benbear.oedapp;

import be.hepl.benbear.oedapp.jdbc.SwappableConnection;
import javafx.stage.Stage;

import java.io.IOException;
import java.nio.file.Paths;
import java.sql.SQLRecoverableException;
import java.util.List;
import java.util.OptionalInt;
import java.util.concurrent.Executor;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class SearchApplication extends BaseApplication {

    private static byte[] EMPTY_IMAGE;
    private static byte[] LOADING_IMAGE;

    public static void main(String[] args) {
        launch(args);
    }

    private final ExecutorService threadPool = Executors.newFixedThreadPool(2);
    private SwappableConnection connection;
    private String user;

    public SearchApplication() {
        super(getResource("style.css"));
    }

    @Override
    public void start(Stage stage) throws IOException {
        open("SearchApplication.fxml", "RQS - Search", stage, true);
    }

    @Override
    public void init() throws Exception {
        List<String> params = getParameters().getRaw();
        if(params.isEmpty()) {
            throw new IllegalArgumentException("Usage: java -jar file.jar <config>");
        }
        Config config = new Config(Paths.get(params.get(0)));
        String driver = config.getStringThrowing("master.jdbc_driver");
        Class.forName(driver);

        String jdbc = config.getStringThrowing("master.jdbc_url");
        String username = config.getStringThrowing("master.username");
        String password = config.getStringThrowing("master.password");
        connection = new SwappableConnection(
            e -> e instanceof SQLRecoverableException || e.getErrorCode() == 20100,
            jdbc, username, password);

        OptionalInt optSlaveCount = config.getInt("slaves.count");
        if(optSlaveCount.isPresent()) {
            for(int i = 0; i < optSlaveCount.getAsInt(); ++i) {
                jdbc = config.getStringThrowing("slaves." + i + ".jdbc_url");
                username = config.getStringThrowing("slaves." + i + ".username");
                password = config.getStringThrowing("slaves." + i + ".password");
                connection.registerSlave(jdbc, username, password);
            }
        }

        connection.connect();
    }

    @Override
    public void stop() throws Exception {
        if(!connection.isClosed()) {
            System.out.println("Closing connection");
            connection.close();
        }
        threadPool.shutdown();
    }

    public SwappableConnection getConnection() {
        return connection;
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

    public SearchApplication connectUser(String user) {
        this.user = user;
        return this;
    }

    public SearchApplication disconnectUser() {
        user = null;
        return this;
    }

    public String getUser() {
        return user;
    }

}
