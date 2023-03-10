/**
 * Created by IntelliJ IDEA.
 * User: ilya
 * Date: 20.04.11
 * Time: 20:50
 * To change this template use File | Settings | File Templates.
 */
package ru.ipo.kio._13.checker {
import flash.display.Sprite;

import com.adobe.serialization.json.JSONParseError;
import com.adobe.serialization.json.JSON_k;

import flash.events.Event;
import flash.events.TimerEvent;
import flash.net.FileFilter;
import flash.net.FileReference;
import flash.text.TextField;
import flash.utils.ByteArray;
import flash.utils.Timer;
import flash.utils.getTimer;

import nochump.util.zip.ZipEntry;
import nochump.util.zip.ZipFile;
import nochump.util.zip.ZipOutput;

import ru.ipo.kio._13.blocks.BlocksProblem;
import ru.ipo.kio._13.clock.ClockProblem;
import ru.ipo.kio._13.clock.model.SettingsHolder;
import ru.ipo.kio._13.clock.model.TransmissionMechanism;
import ru.ipo.kio._13.cut.CutProblem;
import ru.ipo.kio.api.KioApi;
import ru.ipo.kio.api.KioProblem;
import ru.ipo.kio.base.KioBase;

public class KioChecker65 extends Sprite {

    private var output:ZipOutput = new ZipOutput();

    //noinspection JSMismatchedCollectionQueryUpdate,JSUnusedLocalSymbols

    private var zip:ZipFile;
    private var zip_entries:Array;
    private var certificates:Array = [
        [],
        [],
        []
    ]; //levels 0, 1, 2
    private var logText:TextField;

    private static var FROM_ENTRY:int = 0;
    private static var TO_ENTRY:int = 50;
    private static const NEED_RESULTS:Boolean = true; //need create csv files with results
    private static const OUTPUT_LOGS:Boolean = false; //output only logs
    private static const OUTPUT_ONLY_NEW_CERTS:Boolean = false;

    private var old_checked_logins:Array = [];
    private var new_checked_logins:Array = [];

    private var time_start:int;

    private var checkerProblems:Array;

    public function KioChecker65() {
        KioApi.isChecker = true;
        logText = new TextField();
        logText.multiline = true;
        logText.x = 0;
        logText.y = 0;
        logText.width = 800;
        logText.height = 550;
        addChild(logText);

        go();
    }

    public function go():void {

        //open file with zip of solutions
        var fr:FileReference = new FileReference();

        fr.addEventListener(Event.SELECT, function(e:Event):void {
            fr.load();
        });
        fr.addEventListener(Event.COMPLETE, function(e:Event):void {
            var nums_in_name:Array = fr.name.match(/\d+/g);
            if (nums_in_name.length < 2)
                throw 'Input file should have numbers: ' + fr.name;
            FROM_ENTRY = nums_in_name[nums_in_name.length - 2];
            TO_ENTRY = nums_in_name[nums_in_name.length - 1];

            //open file with previous certs
            //open file with zip of solutions
            var frC:FileReference = new FileReference();

            frC.addEventListener(Event.SELECT, function(e:Event):void {
                frC.load();
            });
            frC.addEventListener(Event.COMPLETE, function(e:Event):void {
                var zip:ZipFile = new ZipFile(frC.data);

                for each (var entry:ZipEntry in zip.entries) {
                    //noinspection JSMismatchedCollectionQueryUpdate
                    var ma:Array = entry.name.match(/\.kio--c$/);
                    if (!ma || ma.length == 0)
                        continue;
                    var input:ByteArray = zip.getInput(entry);
                    var json:String = input.readUTFBytes(input.length);
                    var cert:Object = JSON_k.decode(json);
                    old_checked_logins.push(getLogin(entry.name));
                    certificates[cert._level].push(cert);
                }

                var zipSols:ZipFile = new ZipFile(fr.data);
                processSolutions(zipSols);
            });
            frC.addEventListener(Event.CANCEL, function(e:Event):void {
                var zipSols:ZipFile = new ZipFile(fr.data);
                processSolutions(zipSols);
            });

            frC.browse([
                new FileFilter("zip", "*.zip"),
                new FileFilter("all", "*.*")
            ]);
        });

        fr.browse([
            new FileFilter("zip", "*.zip"),
            new FileFilter("all", "*.*")
        ]);
    }

    private static function getLogin(fileName:String):String {
        var pnt:int = fileName.lastIndexOf('.');
        var nam:int = fileName.indexOf('/');
        if (pnt >= 0)
            fileName = fileName.substring(0, pnt);
        if (nam >= 0)
            fileName = fileName.substring(nam + 1);
        return fileName;
    }

    private function log(message:String):void {
        var d:Date = new Date();
        var traceMessage:String = d.toLocaleTimeString() + ": " + message;
        trace(traceMessage);

        if (logText.text.length > 10000)
            logText.text = logText.text.substr(0, 500) + "\n ... cleared";

        logText.text = traceMessage + "\n" + logText.text;
    }

    private function write(fileName:String, data:*):void {
        var entry:ZipEntry = new ZipEntry(fileName);
        var fileData:ByteArray = new ByteArray();
        fileData.writeMultiByte(data, 'x-cp1251');
        output.putNextEntry(entry);
        output.write(fileData);
        output.closeEntry();
    }

    private function processZipEntry(index:int):void {
        if (index >= zip_entries.length) {
            log ("last zip entry encountered:" + zip_entries.length);
        }
        if (index >= zip_entries.length || index > TO_ENTRY) {
            writeTemporaryCerts(index - 1);

            if (NEED_RESULTS)
                writeData(index - 1);

            return;
        }

        log("ENTRY # " + index + " of (" + FROM_ENTRY + "-" + TO_ENTRY + ")");

        var entry:ZipEntry = zip_entries[index];

        //noinspection LoopStatementThatDoesntLoopJS
        while (true) {
            var login:String = entry.name;
            //remove extension, skip entry if there is no extension
            var last_point:int = login.lastIndexOf('.');
            if (last_point == -1) {
                log("skipping entry " + entry.name);
                break;
            }
            login = login.substring(0, last_point);
            //remove folder
            var last_slash:int = login.lastIndexOf('/');
            if (last_slash >= 0)
                login = login.substring(last_slash + 1);

            //what if there are files with the same name but different extensions
            login += '@' + entry.name.substring(last_point + 1);

            //test if the login was already checked

            if (old_checked_logins.indexOf(login) >= 0) {
                log("DOUBLE LOGIN SKIPPED: " + login);
                break;
            }

            log("solution found for login " + login);
            new_checked_logins.push(login);
            var certificate:Object = processSolution(login, zip.getInput(entry));

            if (certificate)
                certificates[certificate._level].push(certificate);
            break;
        }

        var continuation:Timer = new Timer(10, 1);
        continuation.addEventListener(TimerEvent.TIMER, function(e:Event):void {
            processZipEntry(index + 1);
        });
        continuation.start();
    }

    private function processSolutions(zip:ZipFile):void {
        KioApi.language = KioApi.L_RU;
        checkerProblems = [
//            [new CutProblem(0), new BlocksProblem(0), new ClockProblem(0)],
//            [new CutProblem(1), new BlocksProblem(1), new ClockProblem(1)],
//            [new CutProblem(2), new BlocksProblem(2), new ClockProblem(2)]
              CutProblem, BlocksProblem, ClockProblem
        ];

        this.zip = zip;
        this.zip_entries = [];
        for each (var e:ZipEntry in zip.entries)
            this.zip_entries.push(e);

        time_start = getTimer();
        processZipEntry(FROM_ENTRY);
        log('Done in ' + (getTimer() - time_start) + ' ms.');
    }

    private function writeTemporaryCerts(last_cert:int):void {
        var c:Object;
        for each (c in certificates[0])
            write(c._login + '.kio--c', JSON_k.encode(c));
        for each (c in certificates[1])
            write(c._login + '.kio--c', JSON_k.encode(c));
        for each (c in certificates[2])
            write(c._login + '.kio--c', JSON_k.encode(c));


        if (!NEED_RESULTS) {
            output.finish();
            var zipOut:FileReference = new FileReference();
            var date:Date = new Date();
            zipOut.save(output.byteArray,
                    "certs" + '.' + FROM_ENTRY + ' - ' + last_cert + '.' + date.getDay() + '.' + date.getHours() + '.' + date.getMinutes() + ".zip"
                    );
        }
    }

    private function writeData(last_cert:int):void {
        var levelProblems:Array = [
            [new CutProblem(0), new BlocksProblem(0), new ClockProblem(0)],
            [new CutProblem(1), new BlocksProblem(1), new ClockProblem(1)],
            [new CutProblem(2), new BlocksProblem(2), new ClockProblem(2)]
        ];
        var levelProblemHeaders:Array = [
            [
                ['polys', 'pieces', 'offcuts'],
                ['in_place', 'penalty', 'steps'],
                ['absTransmissionError', 'square', 'conflict', 'rightDirection', 'finished']
            ],
            [
                ['polys', 'pieces', 'offcuts'],
                ['in_place', 'prg_len', 'steps'],
                ['absTransmissionError', 'square', 'conflict', 'rightDirection', 'finished']
            ],
            [
                ['polys', 'pieces', 'offcuts'],
                ['in_place', 'prg_len', 'steps'],
                ['absTransmissionError', 'square', 'conflict', 'rightDirection', 'finished']
            ]
        ];

        for each (var l:int in [0, 1, 2])
            for each (var problem_l:KioProblem in levelProblems[l])
                sortCertificatesAndFillScores(problem_l, certificates[l]);

        //sum scores in all certificates
        for each (var level:int in [0, 1, 2]) {
            for each (var cert:Object in certificates[level])
                cert._scores = int(
                        cert[levelProblems[level][0].id + '_scores'] +
                        cert[levelProblems[level][1].id + '_scores'] +
                        cert[levelProblems[level][2].id + '_scores']
                );
        }

        for each (l in [0, 1, 2])
            sortCertificatesAndFillRank(certificates[l]);

        for each (l in [0, 1, 2])
            for each (var c:Object in certificates[l])
                if (!OUTPUT_ONLY_NEW_CERTS || new_checked_logins.indexOf(c._login) != -1)
                    write(removeSqBrackets(c._login) + '.kio-certificate', JSON_k.encode(sign(c)));
        for each (l in [0, 1, 2])
            makeTable(l, certificates[l], levelProblems[l], levelProblemHeaders[l]);

        output.finish();
        var zipOut:FileReference = new FileReference();
        var date:Date = new Date();
        zipOut.save(output.byteArray, "checker" + '.' + FROM_ENTRY + ' - ' + last_cert + '.' + date.getDay() + '.' + date.getHours() + '.' + date.getMinutes() + ".zip");
    }

    //some logins that came from the tmp dir start with [] so we need to remove them
    private static function removeSqBrackets(login:String):String {
        return login.replace(/\[.+]/, '');
    }

    private static function addText(text:String, table:Object):void {
        if (text == null)
            text = "";

        text = text.replace(/"/g, '""');

        table.text += '"' + text + '";';
    }

    private function makeTable(level:int, certificates:Array, levelProblem:Array, levelProblemHeader:Array):void {
        var table:Object = {text:""};

        //write header
        addText("login", table);
        addText("rank", table);
        addText("scores", table);
        addText("-", table);
        //add for problems

        var p_id:int;
        var headers:Array;
        var header:String;

        for (p_id = 0; p_id < 3; ++p_id) {
            headers = levelProblemHeader[p_id];

            for each (header in headers)
                addText(header, table);
            addText('scores', table);
            addText('-', table);
        }

        var anketa_headers:Array = ['surname', 'name', 'second_name', 'email', 'inst_name', 'grade', 'address'];
        for each (header in anketa_headers)
            addText(header, table);

        table.text += "\n";

        for each (var certificate:Object in certificates) {
            addText(certificate._login, table);
            addText(certificate._rank, table);
            addText(certificate._scores, table);
            addText('', table);

            for (p_id = 0; p_id < 3; ++p_id) {
                var p:KioProblem = levelProblem[p_id];
                headers = levelProblemHeader[p_id];
                var problem_result:Object = certificate[p.id];

                for each (header in headers)
                    if (!problem_result)
                        addText('', table);
                    else {
                        if (problem_result[header] == null) { //"bas-0005-003-1@kio-1" (level 1)
                            trace('Error! problem_result[header] == null');
                            trace('login = ' + certificate._login);
                            trace('problem_result = ' + JSON_k.encode(problem_result));
                            trace('header = ' + header);
                            problem_result[header] = '(!)null(!)';
                        }
                        addText(problem_result[header], table);
                    }

                addText(certificate[p.id + '_scores'], table);
                addText('', table);
            }

            for each (header in anketa_headers)
                addText(certificate._anketa[header], table);

            table.text += "\n";
        }

        write('kio-results-' + level + '.csv', table.text);
    }

    private static function sortCertificatesAndFillRank(certificates:Array):void {
        certificates.sortOn("_scores", Array.DESCENDING | Array.NUMERIC);
        var N:int = certificates.length;
        if (N == 0)
            return;
        var rank:int = 300;
        certificates[0]._rank = rank;
        for (var i:int = 1; i < N; ++i) {
            if (certificates[i]._scores != certificates[i - 1]._scores)
                rank++;
            certificates[i]._rank = rank;
        }
    }

    private function sortCertificatesAndFillScores(problem:KioProblem, certificates:Array, scores_in_problem:String = null):void {
        var N:int = certificates.length;
        var scores_ind:String = problem.id + '_scores';

        //bubble sort

        var comparator:Function = function(i:int, j:int):int {
            var res1:Object = certificates[i][problem.id];
            var res2:Object = certificates[j][problem.id];

            if (res1 == null && res2 == null)
                return 0;
            else if (res1 == null)
                return -1;
            else if (res2 == null)
                return 1;

            return problem.compare(res1, res2);
        };

        for (var i:int = 0; i < N; ++i)
            for (var j:int = i + 1; j < N; ++j)
                if (comparator(i, j) > 0) {
                    var temp:* = certificates[i];
                    certificates[i] = certificates[j];
                    certificates[j] = temp;
                }

        if (N == 0)
            return;

        //make null solutions {}

        //fill scores
        var scores:int = 0;

        for (i = 0; i < N; ++i) {
            if (i > 0 && comparator(i - 1, i) < 0)
                scores = i;

            if (scores_in_problem)
                certificates[i][problem.id][scores_in_problem] = scores;
            else
                certificates[i][scores_ind] = scores;
        }
    }

    private static const _TRIM_PATTERN:RegExp = /^\s*|\s*$/g;

    public static function trim(text:String):String {
        return text.replace(_TRIM_PATTERN, "");
    }

    private function processSolution(login:String, input:ByteArray):Object {
        var solUTF:String = input.readMultiByte(input.length, 'windows-1251');
        try {
            var data:* = solUTF.split(';');
        } catch (e:JSONParseError) {
            log('Solution parse error for login: ' + login);
            return null;
        }

        var level:int = data[0];
        var anketa:* = {
            surname: trim(data[22]),
            name: trim(data[23]),
            second_name: trim(data[24])
        };
        var language:String = 'ru';
        KioApi.language = language;
        log("level, language, name = " + level + ", " + language + ", " +
                anketa.surname + " " +
                anketa.name + " " +
                anketa.second_name + " ");

        var certificate:Object = {
            _login: login,
            _level: level,
            _anketa : anketa
        };

//        for each (var problem:KioProblem in checkerProblems[level]) {
        for each (var problemClass:Class in checkerProblems) {
            //only for 2013
            SettingsHolder.clearInstance();
            TransmissionMechanism.clearInstance();
            var problem:KioProblem = new problemClass(level);

            //get and log problem title
            var problemLocalization:Object = KioApi.getLocalization(problem.id);
            var problem_title:String = problemLocalization.title;
            if (!problem_title)
                problem_title = problemLocalization["title" + problem.level];

            log("checking problem " + problem_title);
            var t:int = getTimer();

            if (problemClass == CutProblem)
                certificate[problem.id] = {
                    polys: data[5],
                    pieces: data[6],
                    offcuts: data[7]
                };
            else if (problemClass == BlocksProblem) {
                certificate[problem.id] = {
                    in_place: data[10],
                    steps: data[12]
                };
                if (level == 0)
                    certificate[problem.id].penalty = data[11];
                else
                    certificate[problem.id].prg_len = data[11];
            }
            else if (problemClass == ClockProblem)
                certificate[problem.id] = {
                    absTransmissionError: data[15],
                    square: 42
                };

            KioApi.clearInstance();
        }

        log('Time from the beginning ' + (getTimer() - time_start) + ' ms.');

        return certificate;
    }

    public static function signString(s:String):int {
        var b : ByteArray = new ByteArray();
        b.writeUTF(s);
        b.position = 0;
        var res:int = 0;
        for(var i:int = 0; i < b.length; i++) {
            res *= 19;
            res += (b.readByte() + 256);
            res %= 1299709;
        }
        return res;
    }

    private static function sign(certificate:Object):Object {
        var cert:String = JSON_k.encode(certificate);

        return {
            json_certificate: cert,
            signature: signString(cert) //TODO implement public key cryptography and don't upload private keys to google code
        };
    }
}
}