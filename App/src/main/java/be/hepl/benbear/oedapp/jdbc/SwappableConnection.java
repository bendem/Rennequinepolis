package be.hepl.benbear.oedapp.jdbc;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.function.Consumer;
import java.util.function.Predicate;

public class SwappableConnection {

    @FunctionalInterface
    public interface SQLCallable<T> {
        T execute() throws SQLException;
    }

    @FunctionalInterface
    public interface SQLRunnable {
        void execute() throws SQLException;
    }

    @FunctionalInterface
    public interface SQLConsumer<T> {
        void accept(T t) throws SQLException;
    }

    private final String[] master;
    private final List<String[]> slaves;
    private Predicate<SQLException> switchPredicate;
    private Connection connection;
    private boolean disconnected = false;

    public SwappableConnection(Predicate<SQLException> predicate, String jdbc, String username, String password) {
        switchPredicate = predicate;
        master = new String[] { jdbc, username, password };
        slaves = new ArrayList<>();
    }

    public SwappableConnection registerSlave(String jdbc, String username, String password) {
        slaves.add(new String[] { jdbc, username, password });
        return this;
    }

    public SwappableConnection connect() {
        if(disconnected) {
            throw new IllegalStateException("Disconnected flag is set");
        }

        if(connection != null) {
            try {
                connection.close();
            } catch(SQLException e) {}
        }

        try {
            connection = DriverManager.getConnection(master[0], master[1], master[2]);
            connection.setAutoCommit(false);
            return this;
        } catch(SQLException e) {
            for(String[] info : slaves) {
                try {
                    connection = DriverManager.getConnection(info[0], info[1], info[2]);
                    connection.setAutoCommit(false);
                    return this;
                } catch(SQLException e1) {}
            }
        }

        throw new RuntimeException("Could not contact master and slaves");
    }

    /**
     * Possibly handles a sql error by switching connection.
     *
     * @param e the exception to handle
     * @return true if the exception was handled, false if it still needs handling
     */
    private boolean handleError(SQLException e) {
        if(switchPredicate.test(e)) {
            System.err.println("Reconnecting");
            connect();
            return true;
        }
        return false;
    }

    public <T> T execute(SQLCallable<T> operation) throws SQLException {
        while(true) {
            try {
                return operation.execute();
            } catch(SQLException e) {
                if(!handleError(e)) {
                    throw e;
                }
            }
        }
    }

    public PreparedStatement prepareStatement(String sql) throws SQLException {
        return execute(() -> connection.prepareStatement(sql));
    }

    public void preparedStatement(String sql, SQLConsumer<PreparedStatement> binder, SQLConsumer<ResultSet> consumer, Consumer<SQLException> errorHandler) {
        System.err.println(sql);
        while(true) {
            try(PreparedStatement stmt = connection.prepareStatement(sql)) {
                binder.accept(stmt);
                try(ResultSet rs = stmt.executeQuery()) {
                    consumer.accept(rs);
                    return;
                }
            } catch(SQLException e) {
                if(!handleError(e)) {
                    errorHandler.accept(e);
                    return;
                }
            }
        }
    }

    public CallableStatement prepareCall(String sql) throws SQLException {
        return execute(() -> connection.prepareCall(sql));
    }

    public void preparedCall(String sql, SQLConsumer<CallableStatement> action, Consumer<SQLException> errorHandler) {
        System.err.println(sql);
        while(true) {
            try(CallableStatement stmt = connection.prepareCall(sql)) {
                action.accept(stmt);
                return;
            } catch(SQLException e) {
                if(!handleError(e)) {
                    errorHandler.accept(e);
                    return;
                }
            }
        }
    }

    public void commit() throws SQLException {
        connection.commit();
    }

    public void rollback() throws SQLException {
        connection.rollback();
    }

    public void close() throws SQLException {
        disconnected = true;
        if(connection != null && !connection.isClosed()) {
            connection.close();
        }
    }

    public boolean isClosed() {
        try {
            return disconnected || connection == null || connection.isClosed();
        } catch(SQLException e) {
            return true;
        }
    }

}
