package be.hepl.benbear.oedapp;

import javafx.scene.image.Image;

import java.io.ByteArrayInputStream;
import java.time.LocalDate;

public class Movie {

    private final int id;
    private final String title;
    private final String originalTitle;
    private final LocalDate releaseDate;
    private final double voteAvg;
    private final int voteCount;
    private final int runtime;
    private final byte[] image;
    private final String overview;

    public Movie(int id, String title, String originalTitle, LocalDate releaseDate,
                 double voteAvg, int voteCount, int runtime, byte[] image, String overview) {
        this.id = id;
        this.title = title;
        this.originalTitle = originalTitle;
        this.releaseDate = releaseDate;
        this.voteAvg = voteAvg;
        this.voteCount = voteCount;
        this.runtime = runtime;
        this.image = image;
        this.overview = overview;
    }

    public int getId() {
        return id;
    }

    public String getTitle() {
        return title;
    }

    public String getOriginalTitle() {
        return originalTitle;
    }

    public LocalDate getReleaseDate() {
        return releaseDate;
    }

    public double getVoteAvg() {
        return voteAvg;
    }

    public int getVoteCount() {
        return voteCount;
    }

    public int getRuntime() {
        return runtime;
    }

    public Image getImage() {
        return new Image(new ByteArrayInputStream(image));
    }

    public String getOverview() {
        return overview;
    }
}