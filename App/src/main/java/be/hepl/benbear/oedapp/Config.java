package be.hepl.benbear.oedapp;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Map;
import java.util.Optional;
import java.util.OptionalInt;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

public class Config {

    private final Map<String, String> data;

    public Config(Path path) throws IOException {
        if(!Files.isRegularFile(path)) {
            throw new IllegalArgumentException("config not found at " + path.toAbsolutePath());
        }
        this.data = new ConcurrentHashMap<>();

        load(path);
    }

    public OptionalInt getInt(String name) {
        String value = data.get(name);
        if(value == null) {
            return OptionalInt.empty();
        }
        try {
            return OptionalInt.of(Integer.parseInt(value));
        } catch(NumberFormatException e) {
            System.err.println(e.getMessage());
            e.printStackTrace();
            return OptionalInt.empty();
        }
    }

    public int getIntThrowing(String name) {
        return getInt(name).orElseThrow(() -> new RuntimeException(name + " not found in the config"));
    }

    public Optional<String> getString(String name) {
        return Optional.ofNullable(data.get(name));
    }

    public String getStringThrowing(String name) {
        return getString(name).orElseThrow(() -> new RuntimeException(name + " not found in the config"));
    }

    public Config load(String path) throws IOException {
        if(path != null) {
            load(Paths.get(path));
        }
        return this;
    }

    public Config load(Path path) throws IOException {
        Map<String, String> collected = Files.lines(path)
            .map(String::trim)
            .filter(l -> !l.isEmpty())
            .filter(l -> !l.startsWith("#"))
            .filter(l -> !l.startsWith(";"))
            .filter(l -> !l.startsWith("//"))
            .filter(l -> {
                if(!l.contains("=")) {
                    System.err.println("Ignored invalid line: '" + l + "'");
                    return false;
                }
                return true;
            })
            .map(l -> {
                int i = l.indexOf('=');
                return new String[]{l.substring(0, i), l.substring(i + 1)};
            })
            .collect(Collectors.toMap(
                p -> p[0].trim(),
                p -> p[1].trim(),
                (a, b) -> b
            ));
        data.putAll(collected);

        return this;
    }

}
