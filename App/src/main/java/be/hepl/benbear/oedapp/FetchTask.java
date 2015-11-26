package be.hepl.benbear.oedapp;

import be.hepl.benbear.oedapp.jdbc.SwappableConnection;
import javafx.application.Platform;
import javafx.beans.property.ReadOnlyListProperty;
import javafx.beans.property.ReadOnlyListWrapper;
import javafx.collections.FXCollections;
import javafx.concurrent.Task;

import java.sql.CallableStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class FetchTask<T> extends Task<Integer> {

    private final SwappableConnection connection;
    private final QueryBuilder cs;
    private final ResultSetMapper<T> mapping;
    private final ReadOnlyListWrapper<T> values;

    public FetchTask(SwappableConnection connection, QueryBuilder cs, ResultSetMapper<T> mapping) {
        this.connection = connection;
        this.cs = cs;
        this.mapping = mapping;
        this.values = new ReadOnlyListWrapper<>(FXCollections.observableArrayList());
    }

    @Override
    protected final Integer call() throws Exception {
        return connection.execute(() -> {
            int count = 0;

            try(CallableStatement cs = this.cs.build()) {
                cs.execute();
                try(ResultSet rs = (ResultSet) cs.getObject(1)) {
                    while(rs.next()) {
                        if(isCancelled()) {
                            break;
                        }

                        ++count;
                        updateValue(count);
                        nonThrottledUpdate(mapping.map(rs));
                    }
                }
            }

            return count;
        });
    }

    public ReadOnlyListProperty<T> fetchedValuesProperty() {
        return values.getReadOnlyProperty();
    }

    protected void nonThrottledUpdate(T value) {
        Platform.runLater(() -> values.add(value));
    }

    @FunctionalInterface
    public interface QueryBuilder {
        CallableStatement build() throws SQLException;
    }

    @FunctionalInterface
    public interface ResultSetMapper<T> {
        T map(ResultSet rs) throws SQLException;
    }

}
