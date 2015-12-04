package be.hepl.benbear.oedapp.jdbc;

import java.sql.SQLException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public final class ExceptionUtil {

    private static final Pattern EXTRACT_MESSAGE = Pattern.compile("ORA-[0-9]{5}:\\s*([^\\n]+).*", Pattern.MULTILINE | Pattern.DOTALL);

    private ExceptionUtil() {}

    public static String extractMessage(SQLException e) {
        Matcher matcher = EXTRACT_MESSAGE.matcher(e.getMessage());
        if(matcher.matches()) {
            return matcher.group(1);
        } else {
            return e.getMessage();
        }
    }

}
