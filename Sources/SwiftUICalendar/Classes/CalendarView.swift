//
//  CalendarView.swift
//  SwiftUICalendar
//
//  Created by GGJJack on 2021/10/26.
//

import SwiftUI
import Combine

public struct CalendarView<CalendarCell: View, HeaderCell: View, MonthHeader: View>: View {
    
    private var gridItem: [GridItem] = Array(repeating: .init(.flexible(minimum: 0), spacing: 0), count: 7) // columnCount
    private let component: (YearMonthDay) -> CalendarCell
    private let monthHeader: (YearMonthDay) -> MonthHeader?
    private let header: (Week) -> HeaderCell?
    private var headerSize: HeaderSize
    @ObservedObject private var controller: CalendarController
    private let hasHeader: Bool
    private let hasMonthHeader: Bool
    private var startWithMonday: Bool
    
    public init(
        _ controller: CalendarController = CalendarController(),
        startWithMonday: Bool = false,
        @ViewBuilder component: @escaping (YearMonthDay) -> CalendarCell
    ) where HeaderCell == EmptyView, MonthHeader == EmptyView {
        self.controller = controller
        self.startWithMonday = startWithMonday
        self.header = { _ in nil }
        self.monthHeader = {_ in nil}
        self.component = component
        self.hasHeader = false
        self.hasMonthHeader = false
        self.headerSize = .zero
    }
    
    public init(
        _ controller: CalendarController = CalendarController(),
        startWithMonday: Bool = false,
        headerSize: HeaderSize = .fixHeight(40),
        @ViewBuilder monthHeader: @escaping (YearMonthDay) -> MonthHeader,
        @ViewBuilder header: @escaping (Week) -> HeaderCell,
        @ViewBuilder component: @escaping (YearMonthDay) -> CalendarCell
    ) {
        self.controller = controller
        self.startWithMonday = startWithMonday
        self.hasHeader = true
        self.header = header
        self.headerSize = headerSize
        self.hasMonthHeader = true
        self.monthHeader = monthHeader
        self.component = component
    }
    
    public var body: some View {
        GeometryReader { proxy in
            InfinitePagerView(controller, orientation: controller.orientation) { yearMonth, i in
                LazyVGrid(columns: gridItem, alignment: .center, spacing: 0) {
                    ForEach(-1..<(controller.columnCount * (controller.rowCount + (hasHeader ? 1 : 0))), id: \.self) { j in
                        // TODO: Not compatible with month view
                        if j == -1 {
                            Color.clear
                                .frame(height: 24)
                                .overlay(alignment: .topLeading) {
                                    monthHeader(yearMonth.cellToDate(10, startWithMonday: startWithMonday))?
                                        .frame(width: proxy.size.width, height: 24)
                                }
                            
                            ForEach(1...6, id: \.self) { _ in
                                Color.clear
                            }
                        }
                        
                        else {
                            GeometryReader { geometry in
                                if hasHeader && j < controller.columnCount {
                                    header(Week.allCases[!self.startWithMonday ? j : j < 6 ? j + 1 : 0])
                                } else {
                                    let date = yearMonth.cellToDate(j - (hasHeader ? 7 : 0), startWithMonday: startWithMonday)
                                    self.component(date)
                                }
                            }
                            .frame(height: calculateCellHeight(j, geometry: proxy))
                        }
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
            }
        }
    }
    
    func calculateCellHeight(_ index: Int, geometry: GeometryProxy) -> CGFloat {
        if !hasHeader {
            return geometry.size.height / CGFloat(controller.rowCount)
        }

        var headerHeight: CGFloat = 0
        switch headerSize {
        case .zero:
            headerHeight = 0
        case .ratio:
            headerHeight = geometry.size.height / CGFloat(controller.rowCount + 1)
        case .fixHeight(let value):
            headerHeight = value
        }
        
        if hasMonthHeader && index == -1 {
            headerHeight += 24
        }

        if index < controller.columnCount {
            return headerHeight
        } else {
            return (geometry.size.height - headerHeight) / CGFloat(controller.rowCount + (hasMonthHeader ? 1 : 0))
        }
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView(
            CalendarController(),
            monthHeader: { date in
                Text("\(date.month) \(String(date.year))")
            },
            header: { week in
                GeometryReader { geometry in
                    Text(week.shortString)
                        .font(.subheadline).bold()
                        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
                }
            },
            component: { date in
                GeometryReader { geometry in
                    Text("\(String(date.year))/\(date.month)/\(date.day)")
                        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
                        .border(.black, width: 1)
                        .font(.system(size: 8))
                        .opacity(date.isFocusYearMonth == true ? 1 : 0.6)
                }
            }
        )
    }
}
