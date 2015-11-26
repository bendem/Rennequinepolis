package be.hepl.benbear.oedapp.jdbc;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.function.Consumer;

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

    private final List<String[]> connections;
    private Connection connection;
    private int current = 0;

    public SwappableConnection() {
        connections = new ArrayList<>();
    }

    public SwappableConnection registerConnection(String jdbc, String username, String password) {
        connections.add(new String[] { jdbc, username, password });
        return this;
    }

    public SwappableConnection connect() throws SQLException {
        if(connections.isEmpty()) {
            throw new IllegalStateException("No connection registered");
        }

        if(connection != null && !connection.isClosed()) {
            try {
                connection.close();
            } catch(SQLException e) {
            }
        }

        String[] info = connections.get(increment());
        connection = DriverManager.getConnection(info[0], info[1], info[2]);
        connection.setAutoCommit(false);
        return this;
    }

    private boolean reconnect() {
        try {
            connect();
            return true;
        } catch(SQLException e) {
            return false;
        }
    }

    private int increment() {
        int c = current;
        current = (current + 1) % connections.size();
        return c;
    }

    public <T> T execute(SQLCallable<T> operation) throws SQLException {
        int errors = 0;
        SQLRecoverableException exception;
        do {
            try {
                return operation.execute();
            } catch(SQLRecoverableException e) {
                ++errors;
                exception = e;
                connect();
            }
        } while(errors < connections.size());

        throw exception;
    }

    /*
    public void execute(SQLRunnable operation) throws SQLException {
        int errors = 0;
        SQLRecoverableException exception;
        do {
            try {
                operation.execute();
                return;
            } catch(SQLRecoverableException e) {
                ++errors;
                exception = e;
                connect();
            }
        } while(errors < connections.size());

        throw exception;
    }*/

    public PreparedStatement prepareStatement(String sql) throws SQLException {
        return execute(() -> connection.prepareStatement(sql));
    }

    public void preparedStatement(String sql, SQLConsumer<PreparedStatement> binder, SQLConsumer<ResultSet> consumer, Consumer<SQLException> errorHandler) {
        int errors = 0;
        do {
            try(PreparedStatement stmt = connection.prepareStatement(sql)) {
                binder.accept(stmt);
                try(ResultSet rs = stmt.executeQuery()) {
                    consumer.accept(rs);
                    return;
                }
            } catch(SQLRecoverableException e) {
                while(!reconnect() && errors < connections.size());
            } catch(SQLException e) {
                errorHandler.accept(e);
                return;
            }
        } while(errors < connections.size());
    }

    public CallableStatement prepareCall(String sql) throws SQLException {
        return execute(() -> connection.prepareCall(sql));
    }

    public void preparedCall(String sql, SQLConsumer<PreparedStatement> action, Consumer<SQLException> errorHandler) {
        int errors = 0;
        do {
            try(CallableStatement stmt = connection.prepareCall(sql)) {
                action.accept(stmt);
                return;
            } catch(SQLRecoverableException e) {
                while(!reconnect() && errors < connections.size());
            } catch(SQLException e) {
                errorHandler.accept(e);
                return;
            }
        } while(errors < connections.size());
    }

    public void commit() throws SQLException {
        connection.commit();
    }

    public void rollback() throws SQLException {
        connection.rollback();
    }

    public void close() throws SQLException {
        if(connection != null && !connection.isClosed()) {
            connection.close();
        }
    }

    public boolean isClosed() {
        try {
            return connection == null || connection.isClosed();
        } catch(SQLException e) {
            return true;
        }
    }

}
