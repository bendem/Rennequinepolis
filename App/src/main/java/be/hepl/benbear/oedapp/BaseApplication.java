package be.hepl.benbear.oedapp;

import javafx.application.Application;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.scene.control.Alert;
import javafx.stage.Modality;
import javafx.stage.Stage;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.lang.ref.WeakReference;
import java.lang.reflect.InvocationTargetException;
import java.net.URL;
import java.util.*;

public abstract class BaseApplication extends Application {

    private final Map<Object, WeakReference<Stage>> stages;
    private final Set<URL> stylesheets;
    private Stage mainStage;

    protected BaseApplication(URL... stylesheets) {
        this(Arrays.asList(stylesheets));
    }

    protected BaseApplication(Collection<URL> stylesheets) {
        this.stylesheets = new HashSet<>(stylesheets);
        stages = new WeakHashMap<>();
    }

    public Stage getStage(Object controller) {
        return stages.get(controller).get();
    }

    public Stage getMainStage() {
        return mainStage;
    }

    public void close() {
        stages.values().stream()
            .map(WeakReference::get)
            .filter(s -> s != null)
            .forEach(Stage::close);
        mainStage.close();
    }

    public Alert alert(Alert.AlertType type, String content, Object controller) {
        return alert(type, content, getStage(controller));
    }

    public Alert alert(Alert.AlertType type, String content, Stage parent) {
        Alert alert = new Alert(type, content);
        alert.initModality(Modality.WINDOW_MODAL);
        alert.initOwner(parent);
        return alert;
    }

    public <T> T open(String fxml, String title) throws IOException {
        return open(fxml, title, null, false);
    }

    public <T> T open(String fxml, String title, Stage modal) throws IOException {
        return open(fxml, title, modal, false);
    }

    protected <T> T open(String fxml, String title, Stage modal, boolean main) throws IOException {
        if(main && modal == null) {
            throw new IllegalArgumentException("Stage needs to be provided for the main stage");
        }

        FXMLLoader loader = new FXMLLoader(getResource(fxml));

        loader.setControllerFactory(clazz -> {
            try {
                return clazz.getConstructor(getClass()).newInstance(this);
            } catch(InstantiationException | IllegalAccessException
                | NoSuchMethodException | InvocationTargetException e) {
                throw new RuntimeException("Could not instantiate controller for " + clazz, e);
            }
        });

        Parent app = loader.load();
        Stage stage;

        if(main) {
            this.mainStage = stage = modal;
        } else {
            stage = new Stage();

            if(modal != null) {
                stage.initModality(Modality.WINDOW_MODAL);
                stage.initOwner(modal);
            } else {
                stage.initOwner(mainStage);
            }
        }

        for(URL stylesheet : stylesheets) {
            app.getStylesheets().add(stylesheet.toExternalForm());
        }

        stage.setTitle(title);
        stage.setScene(new Scene(app));
        stage.show();

        T controller = loader.getController();
        stages.put(controller, new WeakReference<>(stage));
        return controller;
    }

    protected static URL getResource(String name) {
        return getResource(BaseApplication.class, name);
    }

    protected static URL getResource(Class<?> clazz, String name) {
        return Objects.requireNonNull(clazz.getClassLoader().getResource(name), "Resource not found: " + name);
    }

    protected InputStream getResourceStream(String name) {
        return Objects.requireNonNull(getClass().getClassLoader().getResourceAsStream(name), "Resource not found: " + name);
    }

    protected byte[] getResourceBytes(String name) {
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
}
