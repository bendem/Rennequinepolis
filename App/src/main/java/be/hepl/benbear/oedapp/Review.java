package be.hepl.benbear.oedapp;

import java.time.LocalDate;

public class Review {

    private final int id;
    private final String username;
    private final int rating;
    private final LocalDate date;
    private final String content;

    public Review(int id, String username, int rating, LocalDate date, String content) {
        this.id = id;
        this.username = username;
        this.rating = rating;
        this.date = date;
        this.content = content;
    }

    public int getId() {
        return id;
    }

    public String getUsername() {
        return username;
    }

    public int getRating() {
        return rating;
    }

    public LocalDate getDate() {
        return date;
    }

    public String getContent() {
        return content;
    }

}
