//
//  TabEnumTests.swift
//  BearReaderApplicationTests
//

import Testing
@testable import BearReaderApplication

struct TabEnumTests {

    @Test func tabRawValuesMatchExpectedIndices() {
        #expect(Tab.trending.rawValue == 0)
        #expect(Tab.recent.rawValue == 1)
        #expect(Tab.blogs.rawValue == 2)
        #expect(Tab.profile.rawValue == 3)
        #expect(Tab.search.rawValue == 4)
    }

    @Test func tabInitFromRawValue() {
        #expect(Tab(rawValue: 0) == .trending)
        #expect(Tab(rawValue: 1) == .recent)
        #expect(Tab(rawValue: 4) == .search)
        #expect(Tab(rawValue: 99) == nil)
    }
}
