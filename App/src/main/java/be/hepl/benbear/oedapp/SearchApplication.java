package be.hepl.benbear.oedapp;

import be.hepl.benbear.oedapp.jdbc.SwappableConnection;
import javafx.stage.Stage;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Objects;
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
        Class.forName("oracle.jdbc.driver.OracleDriver");
        // FIXME Once again, pwd in code :/
        connection = new SwappableConnection("jdbc:oracle:thin:@178.32.41.4:8080:xe", "cb", "cb_bendemiscrazy")
            .registerSlave("jdbc:oracle:thin:@178.32.41.4:8080:xe", "cbb", "cb_bendemiscrazy")
            .connect();
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
