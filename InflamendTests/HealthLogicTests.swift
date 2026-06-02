import XCTest
@testable import Inflamend

final class HealthLogicTests: XCTestCase {
    func testRedFlagDetectorFindsHeavyBleedingAndSeverePain() {
        let assessment = RedFlagDetector.assess(text: "I have severe abdominal pain and lots of blood.")

        XCTAssertTrue(assessment.hasRedFlags)
        XCTAssertTrue(assessment.flags.contains(.severeAbdominalPain))
        XCTAssertTrue(assessment.flags.contains(.heavyBleeding))
        XCTAssertTrue(assessment.safetyCopy.contains("Inflamend is not a doctor"))
    }

    func testStructuredBowelLogCanTriggerRedFlag() {
        let assessment = RedFlagDetector.assess(
            bowelLog: BowelLogInput(bristolType: 6, urgencyScore: 9, blood: .visible, painScore: 8, nighttime: true)
        )

        XCTAssertTrue(assessment.flags.contains(.heavyBleeding))
        XCTAssertTrue(assessment.flags.contains(.severeAbdominalPain))
        XCTAssertTrue(assessment.flags.contains(.rapidWorsening))
    }

    func testRiskScoreUsesCautiousDeterministicFactors() {
        let result = RiskScoreService.calculate(
            RiskScoreInput(
                stoolCountToday: 7,
                baselineStoolCount: 2,
                blood: .visible,
                urgencyScore: 8,
                painScore: 7,
                sleepHours: 4.5,
                missedMedication: true,
                userMarkedFlare: false,
                rapidWorsening: true
            )
        )

        XCTAssertGreaterThanOrEqual(result.score, 80)
        XCTAssertEqual(result.tier, "high")
        XCTAssertTrue(result.factors.contains { $0.label.contains("Bowel frequency") })
        XCTAssertTrue(result.disclaimer.contains("not a diagnosis"))
    }

    func testRiskScoreStaysLowForStableInputs() {
        let result = RiskScoreService.calculate(
            RiskScoreInput(
                stoolCountToday: 1,
                baselineStoolCount: 2,
                blood: .none,
                urgencyScore: 1,
                painScore: 1,
                sleepHours: 8,
                missedMedication: false,
                userMarkedFlare: false,
                rapidWorsening: false
            )
        )

        XCTAssertLessThan(result.score, 30)
        XCTAssertEqual(result.tier, "low")
        XCTAssertTrue(result.factors.isEmpty)
    }

    func testVoiceParserParsesBowelMovementWithoutAutosave() {
        let draft = VoiceLogParser.parse("I had three bowel movements today, Bristol six, some urgency, no blood.")

        XCTAssertEqual(draft.type, .bowel)
        XCTAssertEqual(draft.fields["bristol_type"], "6")
        XCTAssertEqual(draft.fields["blood"], "none")
        XCTAssertTrue(draft.requiresConfirmation)
    }

    func testVoiceParserParsesMedication() {
        let draft = VoiceLogParser.parse("I took mesalamine at 9 AM.")

        XCTAssertEqual(draft.type, .medication)
        XCTAssertEqual(draft.fields["medication_name"], "mesalamine")
        XCTAssertEqual(draft.fields["status"], "taken")
    }

    func testVoiceParserParsesWeight() {
        let draft = VoiceLogParser.parse("My weight is 142 pounds.")

        XCTAssertEqual(draft.type, .weight)
        XCTAssertEqual(draft.fields["weight_value"], "142")
        XCTAssertEqual(draft.fields["unit"], "lb")
    }

    func testMedicationScheduleCalculatesTwiceDailyDoses() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let day = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 1)))
        let schedule = MedicationSchedule(
            medicationName: "Mesalamine",
            dose: "800mg",
            frequency: .twiceDaily,
            times: [
                DateComponents(hour: 8, minute: 0),
                DateComponents(hour: 20, minute: 0)
            ]
        )

        let doses = MedicationScheduleCalculator.doses(for: schedule, on: day, calendar: calendar)

        XCTAssertEqual(doses.count, 2)
        XCTAssertEqual(calendar.component(.hour, from: doses[0].scheduledAt), 8)
        XCTAssertEqual(calendar.component(.hour, from: doses[1].scheduledAt), 20)
    }

    func testReportSummaryUsesPossiblePatternLanguage() {
        let report = ReportSummaryGenerator.plainText(
            ReportSummaryInput(
                daysLogged: 7,
                bowelMovementCount: 18,
                bloodEventCount: 1,
                medicationDosesTaken: 12,
                medicationDosesScheduled: 14,
                possiblePatterns: ["urgency may be higher within 48h of coffee"],
                notes: ["Ask about nighttime symptoms."]
            )
        )

        XCTAssertTrue(report.contains("Self-reported tracking summary"))
        XCTAssertTrue(report.contains("Possible pattern"))
        XCTAssertFalse(report.contains("caused"))
    }

    func testValidationHelpers() {
        XCTAssertTrue(HealthLogValidator.isValidBristolType(4))
        XCTAssertFalse(HealthLogValidator.isValidBristolType(8))
        XCTAssertTrue(HealthLogValidator.isValidScale(10))
        XCTAssertFalse(HealthLogValidator.isValidScale(-1))
        XCTAssertTrue(HealthLogValidator.isValidWeight(142))
        XCTAssertFalse(HealthLogValidator.isValidWaterAmountMl(0))
    }
}
