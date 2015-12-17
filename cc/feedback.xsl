<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="html"/>
    <xsl:template match="/">
        <html>
            <head>
                <style>
                html, body, div, table, tr, td, h1, h2 {
                    padding: 0;
                    margin: 0;
                }
                html {
                    font-family: monospace;
                }
                main {
                    width: 80vw;
                    margin: auto;
                    margin-top: 1em;
                }
                .movie {
                    margin-top: 1em;
                }
                h2 {
                    margin-bottom: 0.2em;
                }
                table {
                    border-collapse: collapse;
                    table-layout: fixed;
                    width: 100%;
                }
                tr {
                    border-top: 1px solid black;
                }
                tr:first-child {
                    border: none;
                }
                tr:nth-child(2n + 1) {
                    background-color: #eee;
                }
                td {
                    border-left: 1px solid black;
                    padding: 0.1em 0.5em;
                }
                td:first-child {
                    border: none;
                }
                .error {
                    width: 5ch;
                    color: #a11;
                }
                .success {
                    width: 7ch;
                    color: #1a1;
                }
                .time {
                    max-width: 16ch;
                }
                .msg {
                    width: calc(80vw - 16ch - 5ch - 3em - 2px);
                }
                </style>
                <title>Schedule feedback</title>
            </head>
            <body>
                <main>
                    <h1>Schedule feedback</h1>
                    <xsl:for-each select="schedules/schedule">
                        <div class="movie">
                            <h2>
                                Movie <xsl:value-of select="movie_id" />
                                at <xsl:value-of select="start" />
                                in hall <xsl:value-of select="hall_id" />
                            </h2>
                            <table>
                                <xsl:for-each select="success|error">
                                    <tr>
                                    <xsl:choose>
                                        <xsl:when test="local-name()='success'">
                                            <td class="success">success</td>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <td class="error">error</td>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                        <td class="time">
                                            <xsl:value-of select="time" />
                                        </td>
                                        <xsl:if test="msg">
                                            <td class="msg">
                                                <xsl:value-of select="msg" />
                                            </td>
                                        </xsl:if>
                                    </tr>
                                </xsl:for-each>
                            </table>
                        </div>
                    </xsl:for-each>
                </main>
            </body>
        </html>
    </xsl:template>
</xsl:stylesheet>
