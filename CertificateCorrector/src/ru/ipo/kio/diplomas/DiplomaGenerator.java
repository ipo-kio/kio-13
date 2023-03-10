package ru.ipo.kio.diplomas;

import au.com.bytecode.opencsv.CSVReader;
import com.itextpdf.text.*;
import com.itextpdf.text.pdf.BaseFont;
import com.itextpdf.text.pdf.PdfContentByte;
import com.itextpdf.text.pdf.PdfWriter;

import java.io.*;

/**
 * Created with IntelliJ IDEA.
 * User: ilya
 * Date: 07.05.13
 * Time: 17:47
 */
public class DiplomaGenerator {

    public static final BaseFont NAME_FONT;
    public static final BaseFont INFO_FONT;

    static {
        try {
            NAME_FONT = BaseFont.createFont("resources/images/AmbassadoreType.ttf", BaseFont.IDENTITY_H, BaseFont.EMBEDDED);
            INFO_FONT = BaseFont.createFont("resources/images/arial_bold.ttf", BaseFont.IDENTITY_H, BaseFont.EMBEDDED);
        } catch (Exception e) {
            throw new IllegalArgumentException();
        }
    }

    public static void main(String[] args) throws Exception {
        //generate one problem diploma
        for (int level = 0; level <= 2; level++)
            for (int problem = 1; problem <= 3; problem ++) {
                String numberPrefix = "Диплом №KIO-01-" + level + problem + "-"; //01 - diplomas for separate problems
                File csvInput = new File("resources/kio-results-" + level + "-" + problem + ".csv");
                File pdfOutput = new File("resources/pdf/kio-results-" + level + "-" + problem + ".pdf");
                outputDiplomas(csvInput, pdfOutput, new OneProblemDiplomaFormatter(level, problem), numberPrefix);
            }

        //output diplomas with degree
        for (int degree = 1; degree <= 5; degree++)
            for (int level = 0; level <= 2; level ++) {
                if (degree >= 4 && level != 2)
                    continue;

                String numberPrefix = "Диплом №KIO-02-" + level + degree + "-";
                File csvInput = new File("resources/kio-results-" + level + "-win.csv");
                File pdfOutput = new File("resources/pdf/kio-results-" + level + "-" + degree + "-win.pdf");

                outputDiplomas(csvInput, pdfOutput, new DegreeDiplomaFormatter(level, degree), numberPrefix);
            }

        //output teachers
        String numberPrefix = "Грамота №KIO-03-00-";
        File csvInput = new File("resources/teachers.csv");
        File pdfOutput = new File("resources/pdf/teachers.pdf");

        outputDiplomas(csvInput, pdfOutput, new TeacherDiplomaFormatter(), numberPrefix);
    }

    private static void outputDiplomas(File csvInput, File outputPdf, DiplomaFormatter formatter, String numberPrefix) throws Exception {
        Document doc = null;
        try {
            doc = new Document(
                    new Rectangle(
                            Utilities.millimetersToPoints(210), Utilities.millimetersToPoints(297)
                    ),
                    0, 0, 0, 0
            );
            PdfWriter writer = PdfWriter.getInstance(doc, new FileOutputStream(outputPdf));

            Image bgImage = Image.getInstance(formatter.getBgImage().getAbsolutePath());
            bgImage.setAbsolutePosition(0, 0);
            bgImage.scaleAbsolute(Utilities.millimetersToPoints(210), Utilities.millimetersToPoints(297));

            doc.open();

            CSVReader reader = new CSVReader(new InputStreamReader(new FileInputStream(csvInput), "windows-1251"), ';', '"', 1);
            String[] csvLine;
            int diplomaIndex = 2;
            while ((csvLine = reader.readNext()) != null) {
                if (!formatter.accepts(csvLine))
                    continue;

                doc.newPage();
                doc.add(bgImage);

                PdfContentByte canvas = writer.getDirectContent();

                String diplomaNumber = numberPrefix + makeDigits(3, diplomaIndex);

                canvas.saveState();
                canvas.beginText();

                formatter.format(canvas, csvLine);
                formatter.drawCenteredText(canvas, INFO_FONT, diplomaNumber, 11, 6);

                canvas.endText();
                canvas.restoreState();

                diplomaIndex ++;
            }
        } catch (Exception e) {
            e.printStackTrace();
            throw e;
        } finally {
            if (doc != null)
                doc.close();
        }

    }

    private static String makeDigits(int length, int number) {
        String result = Integer.toString(number);
        while (result.length() < length)
            result = "0" + result;
        return result;
    }

}