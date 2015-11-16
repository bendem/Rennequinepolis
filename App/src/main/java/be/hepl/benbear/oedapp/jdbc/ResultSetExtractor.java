package be.hepl.benbear.oedapp.jdbc;

import java.sql.Date;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Optional;
import java.util.OptionalDouble;
import java.util.OptionalInt;

public class ResultSetExtractor {

    public static OptionalInt getInt(ResultSet rs, String name) throws SQLException {
        int i = rs.getInt(name);
        return rs.wasNull() ? OptionalInt.empty() : OptionalInt.of(i);
    }

    public static OptionalDouble getDouble(ResultSet rs, String name) throws SQLException {
        double i = rs.getDouble(name);
        return rs.wasNull() ? OptionalDouble.empty() : OptionalDouble.of(i);
    }

    public static Optional<String> getString(ResultSet rs, String name) throws SQLException {
        String s = rs.getString(name);
        return rs.wasNull() ? Optional.empty() : Optional.of(s);
    }

    public static Optional<Date> getDate(ResultSet rs, String name) throws SQLException {
        Date d = rs.getDate(name);
        return rs.wasNull() ? Optional.empty() : Optional.of(d);
    }

    public static Optional<byte[]> getBytes(ResultSet rs, String name) throws SQLException {
        byte[] bytes = rs.getBytes(name);
        return rs.wasNull() ? Optional.empty() : Optional.of(bytes);
    }

}
