//
//  Poker_GuessrTests.swift
//  Poker GuessrTests
//

import Testing
import Foundation
@testable import Poker_Guessr

// MARK: - String+Parsing

@Suite("String.extractFirstDouble")
struct StringParsingTests {

    @Test("Parses plain integer")
    func plainInteger() {
        #expect("42".extractFirstDouble() == 42)
    }

    @Test("Parses decimal with dot")
    func decimalDot() {
        #expect("3.14".extractFirstDouble() == 3.14)
    }

    @Test("Parses decimal with comma (German)")
    func decimalComma() {
        #expect("3,14".extractFirstDouble() == 3.14)
    }

    @Test("Parses negative number")
    func negative() {
        #expect("-273".extractFirstDouble() == -273)
    }

    @Test("Extracts first number from sentence")
    func numberInSentence() {
        #expect("Antwort: 100 Meter".extractFirstDouble() == 100)
    }

    @Test("Returns nil for non-numeric string")
    func nonNumeric() {
        #expect("keine Zahl".extractFirstDouble() == nil)
    }

    @Test("Returns nil for empty string")
    func emptyString() {
        #expect("".extractFirstDouble() == nil)
    }

    @Test("Picks first number, not second")
    func firstNumberOnly() {
        #expect("12 oder 34".extractFirstDouble() == 12)
    }

    @Test("Parses positive sign")
    func positiveSign() {
        #expect("+5".extractFirstDouble() == 5)
    }
}

// MARK: - QuizDimension

@Suite("QuizDimension")
struct QuizDimensionTests {

    @Test("All dimensions have at least one option")
    func dimensionsHaveOptions() {
        for dim in QuizDimension.allCases {
            #expect(!dim.options.isEmpty, "\(dim.rawValue) has no options")
        }
    }

    @Test("defaultIndex is within options bounds")
    func defaultIndexInBounds() {
        for dim in QuizDimension.allCases {
            #expect(dim.defaultIndex >= 0)
            #expect(dim.defaultIndex < dim.options.count, "\(dim.rawValue) defaultIndex out of bounds")
        }
    }

    @Test("Weight default is kg with multiplier 1.0")
    func weightDefaultIsKg() {
        let dim = QuizDimension.weight
        let opt = dim.options[dim.defaultIndex]
        #expect(opt.label == "kg")
        #expect(opt.multiplier == 1.0)
    }

    @Test("Length default is m with multiplier 1.0")
    func lengthDefaultIsMeter() {
        let dim = QuizDimension.length
        let opt = dim.options[dim.defaultIndex]
        #expect(opt.label == "m")
        #expect(opt.multiplier == 1.0)
    }

    @Test("Time default is Min.")
    func timeDefaultIsMinutes() {
        let dim = QuizDimension.time
        let opt = dim.options[dim.defaultIndex]
        #expect(opt.label == "Min.")
        #expect(opt.multiplier == 60.0)
    }

    @Test("Multipliers ascend monotonically", arguments: [
        QuizDimension.weight, .length, .time, .volume, .count, .currency
    ])
    func multipliersAscend(dim: QuizDimension) {
        let multipliers = dim.options.map { $0.multiplier }
        for i in 1..<multipliers.count {
            #expect(multipliers[i] > multipliers[i - 1],
                    "\(dim.rawValue) multipliers not strictly ascending at index \(i)")
        }
    }

    @Test("None dimension has neutral option")
    func noneIsNeutral() {
        let dim = QuizDimension.none
        #expect(dim.options.count == 1)
        #expect(dim.options[0].multiplier == 1.0)
    }
}

// MARK: - RankingService

@Suite("RankingService")
struct RankingServiceTests {

    private func makeQuestion(
        baseValue: Double? = 100,
        dimension: QuizDimension? = QuizDimension.length,
        answer: String? = nil
    ) -> QuizItem {
        QuizItem(
            id: nil,
            question: "Test?",
            answer: answer,
            answerBaseValue: baseValue,
            dimension: dimension,
            defaultUnitText: nil,
            category: "Test",
            tips: ["t1", "t2", "t3"],
            difficulty: .easy
        )
    }

    @Test("Three players: closest wins 3, then 2, then 1")
    func threePlayerPodium() {
        let alice = Player(name: "Alice")
        let bob   = Player(name: "Bob")
        let carol = Player(name: "Carol")
        let q = makeQuestion(baseValue: 100, dimension: .length)

        let results = RankingService.calculateRanking(
            for: q,
            players: [alice, bob, carol],
            guesses: [
                alice.id: "120",  // diff 20
                bob.id:   "95",   // diff 5  → winner
                carol.id: "150"   // diff 50
            ],
            unitSelections: [
                alice.id: 2, bob.id: 2, carol.id: 2  // all "m"
            ]
        )

        let r = try! #require(results)
        #expect(r.count == 3)
        #expect(r[0].player.id == bob.id)
        #expect(r[0].points == 3)
        #expect(r[1].player.id == alice.id)
        #expect(r[1].points == 2)
        #expect(r[2].player.id == carol.id)
        #expect(r[2].points == 1)
    }

    @Test("Unit conversion: 1 km vs 1000 m matches target 1000")
    func unitConversion() {
        let alice = Player(name: "Alice")
        let bob   = Player(name: "Bob")
        let q = makeQuestion(baseValue: 1000, dimension: .length)

        let results = RankingService.calculateRanking(
            for: q,
            players: [alice, bob],
            guesses: [
                alice.id: "1",     // 1 km = 1000 m → exact
                bob.id:   "999"    // 999 m → diff 1
            ],
            unitSelections: [
                alice.id: 3,  // km
                bob.id:   2   // m
            ]
        )

        let r = try! #require(results)
        #expect(r[0].player.id == alice.id)
        #expect(r[0].diff == 0)
        #expect(r[1].player.id == bob.id)
        #expect(r[1].diff == 1)
    }

    @Test("Player with invalid guess gets zero points and last rank")
    func invalidGuessGetsZero() {
        let alice = Player(name: "Alice")
        let bob   = Player(name: "Bob")
        let q = makeQuestion(baseValue: 100, dimension: QuizDimension.none)

        let results = RankingService.calculateRanking(
            for: q,
            players: [alice, bob],
            guesses: [
                alice.id: "100",
                bob.id:   "kein Plan"
            ],
            unitSelections: [:]
        )

        let r = try! #require(results)
        #expect(r[0].player.id == alice.id)
        #expect(r[0].points == 3)
        #expect(r[1].player.id == bob.id)
        #expect(r[1].points == 0)
        #expect(r[1].diff == .greatestFiniteMagnitude)
    }

    @Test("Falls back to extractFirstDouble from answer string when baseValue is nil")
    func fallbackToAnswerString() {
        let alice = Player(name: "Alice")
        let q = makeQuestion(baseValue: nil, dimension: QuizDimension.none, answer: "42 Stück")

        let results = RankingService.calculateRanking(
            for: q,
            players: [alice],
            guesses: [alice.id: "42"],
            unitSelections: [:]
        )

        let r = try! #require(results)
        #expect(r.count == 1)
        #expect(r[0].diff == 0)
    }

    @Test("Returns nil when neither baseValue nor parseable answer is present")
    func returnsNilWithoutAnswer() {
        let alice = Player(name: "Alice")
        let q = makeQuestion(baseValue: nil, dimension: QuizDimension.none, answer: nil)

        let results = RankingService.calculateRanking(
            for: q,
            players: [alice],
            guesses: [alice.id: "1"],
            unitSelections: [:]
        )

        #expect(results == nil)
    }

    @Test("Only top three earn points, fourth and beyond earn zero")
    func onlyTopThreeEarnPoints() {
        let players = (1...4).map { Player(name: "P\($0)") }
        let q = makeQuestion(baseValue: 100, dimension: QuizDimension.none)

        let results = RankingService.calculateRanking(
            for: q,
            players: players,
            guesses: [
                players[0].id: "100",
                players[1].id: "101",
                players[2].id: "102",
                players[3].id: "200"
            ],
            unitSelections: [:]
        )

        let r = try! #require(results)
        #expect(r.map(\.points) == [3, 2, 1, 0])
    }

    @Test("Comma-decimal guesses are parsed (German locale)")
    func commaDecimalGuess() {
        let alice = Player(name: "Alice")
        let q = makeQuestion(baseValue: 3.14, dimension: QuizDimension.none)

        let results = RankingService.calculateRanking(
            for: q,
            players: [alice],
            guesses: [alice.id: "3,14"],
            unitSelections: [:]
        )

        let r = try! #require(results)
        #expect(r[0].diff < 0.0001)
    }
}

// MARK: - Difficulty

@Suite("Difficulty")
struct DifficultyTests {

    @Test("All cases have non-empty German display name")
    func displayNamesPresent() {
        for d in Difficulty.allCases {
            #expect(!d.displayName.isEmpty)
        }
    }

    @Test("Raw values are stable lowercase tokens")
    func rawValuesStable() {
        #expect(Difficulty.easy.rawValue == "easy")
        #expect(Difficulty.medium.rawValue == "medium")
        #expect(Difficulty.hard.rawValue == "hard")
    }
}
