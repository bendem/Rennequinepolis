package be.hepl.benbear.oedapp;

import javafx.scene.image.Image;

import java.io.ByteArrayInputStream;

public class Person {

    private final int id;
    private final String name;
    private final byte[] image;

    public Person(int id, String name, byte[] image) {
        this.id = id;
        this.name = name;
        this.image = image;
    }

    public int getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public Image getImage() {
        return new Image(new ByteArrayInputStream(image));
    }

}
