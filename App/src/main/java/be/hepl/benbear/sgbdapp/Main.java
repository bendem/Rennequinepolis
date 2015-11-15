package be.hepl.benbear.sgbdapp;

import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;

import javax.swing.*;

public class Main {
    public static void main(String[] args) throws Exception {
        UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
        JFrame frame = new JFrame("Search Window");
        SearchFrom searchFrom = new SearchFrom();
        frame.addWindowListener(new WindowAdapter() {
            @Override
            public void windowClosed(WindowEvent e) {
                try {
                    // close database
                } catch (Exception e1) {
                    e1.printStackTrace();
                }
            }
        });
        frame.setContentPane(searchFrom.$$$getRootComponent$$$());
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.pack();
        frame.setLocationRelativeTo(null);
        frame.setVisible(true);
    }
}
