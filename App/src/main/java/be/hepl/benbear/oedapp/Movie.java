package be.hepl.benbear.oedapp;

import javafx.scene.image.Image;

import java.io.ByteArrayInputStream;
import java.time.LocalDate;

public class Movie {

    private final int id;
    private final String title;
    private final String originalTitle;
    private final LocalDate releaseDate;
    private final String status;
    private final double voteAvg;
    private final int voteCount;
    private final int runtime;
    private final byte[] image;
    private final int budget;
    private final int revenue;
    private final String homepage;
    private final String tagline;
    private final String overview;

    public Movie(int id, String title, String originalTitle, LocalDate releaseDate,
                 String status, double voteAvg, int voteCount, int runtime, byte[] image, int budget,
                 int revenue, String homepage, String tagline, String overview) {
        this.id = id;
        this.title = title;
        this.originalTitle = originalTitle;
        this.releaseDate = releaseDate;
        this.status = status;
        this.voteAvg = voteAvg;
        this.voteCount = voteCount;
        this.runtime = runtime;
        this.image = image;
        this.budget = budget;
        this.revenue = revenue;
        this.homepage = homepage;
        this.tagline = tagline;
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

    public String getStatus() {
        return status;
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

    public int getBudget() {
        return budget;
    }

    public int getRevenue() {
        return revenue;
    }

    public String getHomepage() {
        return homepage;
    }

    public String getTagline() {
        return tagline;
    }

    public String getOverview() {
        return overview;
    }

}
