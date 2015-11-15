package be.hepl.benbear.oedapp.parser;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Function;

public class SearchParser {

    private static final Function<? super String, ? extends List<String>> SET_COMPUTE = k -> new ArrayList<>();

    private final String defaultPrefix;
    private final boolean lenient;

    public SearchParser(String defaultPrefix) {
        this(defaultPrefix, true);
    }

    public SearchParser(String defaultPrefix, boolean lenient) {
        this.defaultPrefix = defaultPrefix;
        this.lenient = lenient;
    }

    public Map<String, List<String>> parse(String in) {
        Map<String, List<String>> result = new LinkedHashMap<>();

        char[] chars = in.toCharArray();
        StringBuilder sb = new StringBuilder(30);
        String prefix = defaultPrefix;
        boolean quoteOpen = false;

        for(int i = 0; i < chars.length; i++) {
            char c = chars[i];
            switch(c) {
                case '"':
                    if(quoteOpen) {
                        quoteOpen = false;
                        result.computeIfAbsent(prefix, SET_COMPUTE).add(sb.toString());
                        sb.setLength(0);
                        prefix = defaultPrefix;
                    } else {
                        quoteOpen = true;
                    }
                    break;
                case ':':
                    if(quoteOpen) {
                        sb.append(c);
                    } else {
                        prefix = sb.toString();
                        sb.setLength(0);
                    }
                    break;
                case '\\':
                    if(i + 1 < chars.length && (chars[i + 1] == ':' || chars[i + 1] == '"')) { // TODO Check that
                        sb.append(chars[++i]);
                    } else {
                        sb.append(c);
                    }
                    break;
                case '\t':
                case ' ':
                    if(quoteOpen) {
                        sb.append(' ');
                    } else if(sb.length() != 0) {
                        result.computeIfAbsent(prefix, SET_COMPUTE).add(sb.toString());
                        sb.setLength(0);
                        prefix = defaultPrefix;
                    }
                    break;
                default:
                    sb.append(c);
            }
        }

        if(quoteOpen) {
            if(!lenient) {
                throw new ParseException("Unclosed quote at the end of the string");
            }
        }

        if(sb.length() != 0) {
            result.computeIfAbsent(prefix, SET_COMPUTE).add(sb.toString());
        }

        return result;
    }

}
