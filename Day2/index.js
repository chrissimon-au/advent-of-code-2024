const { EOL } = require("os");

function parse(input) {    
    return input
        .split(EOL)
        .map(row => 
            row
            .split(/\s/)
            .map(a => parseInt(a)
        )
    );
}

function adjacentDifferences(report) {
    if (report.length < 2) {
        return [];
    }

    const diffs = report.slice(1).map((value, idx) => {
        return value - report[idx];
    });
    if (diffs[0] < 0) {
        return diffs.map (diff => diff * -1);
    }
    return diffs;
}

function isReportSafe(report) {
    const diffs = adjacentDifferences(report);

    return diffs.filter(diff => diff > 3 || diff < 1).length == 0;
}

function isReportSafeWithProblemDampener(report) {
    const diffs = adjacentDifferences(report);
    const firstProblemIdx = diffs.findIndex(diff => diff > 3 || diff < 1);
    
    const attemptWithoutProblem = report.toSpliced(firstProblemIdx, 1);

    return isReportSafe(attemptWithoutProblem);
}

function numSafeReports(reports) {
    return reports.filter(isReportSafe).length;
}

function numSafeWithProblemDampenerReports(reports) {
    return reports.filter(isReportSafeWithProblemDampener).length;
}

module.exports = {
    parse,
    numSafeReports,
    numSafeWithProblemDampenerReports
} 