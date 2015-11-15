package be.hepl.benbear.oedapp.parser;

import org.junit.Assert;
import org.junit.Test;

import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

public class SearchParserTest {

    @Test
    public void testParseSimpleDefault() {
        SearchParser parser = new SearchParser("default");
        Map<String, List<String>> result = parser.parse("test");
        debug(result);

        Assert.assertEquals("Result should contain one entry", 1, result.size());
        Assert.assertTrue("Result should contain the default key", result.containsKey("default"));
        Assert.assertTrue("Result should contain the test value", result.get("default").contains("test"));
    }

    @Test
    public void testParseWithPrefix() {
        SearchParser parser = new SearchParser("default");
        Map<String, List<String>> result = parser.parse("test:test");
        debug(result);

        Assert.assertEquals("Result should contain one entry", 1, result.size());
        Assert.assertTrue("Result should contain the test key", result.containsKey("test"));
        Assert.assertTrue("Result should contain the test value", result.get("test").contains("test"));
    }

    @Test
    public void testParseComplex() {
        SearchParser parser = new SearchParser("default");
        Map<String, List<String>> result = parser.parse("def default:default test:\"multi words\" test:test");
        debug(result);

        Assert.assertEquals("Result should contain one entry", 2, result.size());
        Assert.assertTrue("Result should contain the default key", result.containsKey("default"));
        Assert.assertTrue("Result should contain the test key", result.containsKey("test"));

        Assert.assertTrue("Result should contain the def value", result.get("default").contains("def"));
        Assert.assertTrue("Result should contain the default value", result.get("default").contains("default"));

        Assert.assertTrue("Result should contain the test value", result.get("test").contains("test"));
        Assert.assertTrue("Result should contain the multi words value", result.get("test").contains("multi words"));
    }

    private void debug(Map<String, ? extends Collection<String>> m) {
        System.out.println(m.entrySet().stream().map(e -> e.getKey() + ':' + e.getValue()).collect(Collectors.joining(", ")));
    }

}
