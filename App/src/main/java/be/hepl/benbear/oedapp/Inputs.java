package be.hepl.benbear.oedapp;

import javafx.beans.value.ChangeListener;
import javafx.scene.Node;
import javafx.scene.control.TextInputControl;
import javafx.scene.input.KeyCode;

import java.util.function.BooleanSupplier;
import java.util.function.Predicate;

public final class Inputs {

    private Inputs() {}

    private static int clamp(int value, int min, int max) {
        return Math.max(min, Math.min(max, value));
    }

    /**
     * Setups listeners on a text input so that only integers between the provided
     * bounds can be entered. Also adds keyboard shortcuts to increase / decrease
     * its value.
     */
    public static void integer(TextInputControl input, int min, int max) {
        if(input.getText().isEmpty()) {
            input.setText(String.valueOf(min));
        }
        input.textProperty().addListener((obs, o, n) -> {
            if(n.isEmpty()) {
                input.setText(String.valueOf(min));
                return;
            }

            try {
                int clamped = clamp(Integer.parseInt(n), min, max);
                if(!n.equals(String.valueOf(clamped))) { // Don't rely on the implementation preventing recursion
                    input.setText(String.valueOf(clamped));
                }
            } catch(NumberFormatException e) {
                input.setText(String.valueOf(min));
            }
        });

        input.setOnKeyTyped(e -> {
            String character = e.getCharacter();
            if(character.length() != 1 || character.charAt(0) < '0' || character.charAt(0) > '9') {
                e.consume();
            }
        });

        input.setOnKeyPressed(e -> {
            if(e.getCode() != KeyCode.UP && e.getCode() != KeyCode.DOWN) {
                return;
            }

            int current = input.getText().isEmpty() ? 0 : Integer.parseInt(input.getText());
            int newCount = (e.getCode() == KeyCode.UP ? 1 : -1) * (e.isControlDown() ? 10 : 1) + current;

            input.setText(String.valueOf(clamp(newCount, min, max)));
            e.consume();
        });
    }

    /**
     * Sets an error state of an text input based on the provided predicate.
     */
    public static void error(TextInputControl element, Predicate<String> hasError) {
        element.textProperty().addListener((obs, o, n) -> {
            if(hasError.test(n)) {
                element.getStyleClass().add("error");
            } else {
                element.getStyleClass().removeAll("error");
            }
        });
    }

    /**
     * Disables a node if any of the provided suppliers returns true when called.
     */
    public static <T> ChangeListener<T> disable(Node toDisable, BooleanSupplier... errorSuppliers) {
        return (obs, o, n) -> {
            for(BooleanSupplier supplier : errorSuppliers) {
                if(supplier.getAsBoolean()) {
                    toDisable.setDisable(true);
                    return;
                }
            }
            toDisable.setDisable(false);
        };
    }

}
