//
//  ContentView.swift
//  SnappingVStack
//
//  Created by Ghiran Sergiu on 23.03.2023.
//

import SwiftUI

struct Item: Identifiable {
    var id: Int
    var color: Color
    var isLive: Bool
}

struct ContentView: View {

    var items: [Item] = [
        Item(id: 0, color: .red, isLive: true),
        Item(id: 1, color: .brown, isLive: false),
        Item(id: 2, color: .blue, isLive: false),
        Item(id: 3, color: .gray, isLive: false),
        Item(id: 4, color: .yellow, isLive: false),
    ]

    @State
    var currentOffset: CGFloat = 0.0
    @State
    var scrolledOffset: CGFloat = 0.0
    @State
    var midContentOffset: CGFloat = 0.0

    @State
    var minScroll: CGFloat = Constants.minScrollFactor
    @State
    var maxScroll = UIScreen.main.bounds.height

    @State
    var currentIndex: Int = 0
    

    init() {
        _maxScroll = State(initialValue: UIScreen.main.bounds.height)

        let (liveIndex, liveOffset, contentHeight) = self.initialParams()

        _currentOffset = State(initialValue: liveOffset)
        _scrolledOffset = State(initialValue: liveOffset)
        _currentIndex = State(initialValue: liveIndex)
        _midContentOffset = State(initialValue: contentHeight / 2)
    }

    var body: some View {

        VStack(spacing: Constants.spacing) {

            ForEach(items) { item in
                RoundedRectangle(cornerRadius: Constants.cornerRadius)
                    .frame(width: Constants.liveSize * self.scaleSize(for: item).width, height: Constants.liveSize * self.scaleSize(for: item).height)
                    .foregroundColor(item.color)
            }
        }
        .frame(maxWidth: .infinity)
        .offset(x: 0, y: scrolledOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    DispatchQueue.main.async {
                        self.scrolledOffset = self.currentOffset + value.translation.height / 2
                    }
                }
                .onEnded { value in
                    DispatchQueue.main.async {
                        withAnimation(.spring()) {
                            let targetOffset = self.targetOffset()
                            currentOffset = targetOffset
                            scrolledOffset = targetOffset
                        }
                    }
                }
        )
    }

//    func deceleratedScroll(with current: CGFloat) -> CGFloat {
//        let percentage = 1.0 - (abs(scrolledOffset) / (maxScroll / 2))
//        print("\n\nInitial value: \(current)")
//        print("Final value: \(current * percentage)")
//        return current * percentage
////        let currentScrollPercent = abs(current) / maxScroll
////        let x = current * currentScrollPercent
////
////        return current - x
//    }

    func scaleSize(for item: Item) -> CGSize {
        // Check to see if we can find the item in the items list
        guard let itemIndex = items.firstIndex(where: { item.id == $0.id }) else {
            return CGSize(width: Constants.scaleFactor, height: Constants.scaleFactor)
        }

        let itemOffset = self.itemOffset(itemIndex)

        // Check to see if the item should indeed be scaled. This only happens if the item the user is scrolling towards (up or down) is within a preset range (benchmark). If not we return a constant size.
        guard abs(itemOffset) < Constants.benchmark else {
            return CGSize(width: Constants.scaleFactor, height: Constants.scaleFactor)
        }

        // We calculate the percentage of dividing the item offset by the benchmark. We basically check to see how close to the current offset the item is.
        let initialPercent = abs(itemOffset) / Constants.benchmark
        let finalPercent = initialPercent * 0.4
        let scalePercent = 1.0 - finalPercent

        return CGSize(width: scalePercent, height: scalePercent)
    }

    func itemOffset(_ itemIndex: Int) -> CGFloat {

        // If the item index is lower than the current index it means the user is scrolling up
        if itemIndex < currentIndex {

            // We calculate the specified item offset from the VStack current center point.
            return (currentOffset + Constants.liveSize / 2 + Constants.spacing + ((Constants.liveSize * Constants.scaleFactor) / 2) * CGFloat((currentIndex - itemIndex) * 2 - 1)) - scrolledOffset
        } else if itemIndex > currentIndex {
            
            // We calculate the specified item offset from the VStack current center point.
            return (currentOffset - Constants.liveSize / 2 - Constants.spacing - ((Constants.liveSize * Constants.scaleFactor) / 2) * CGFloat((itemIndex - currentIndex) * 2 - 1)) - scrolledOffset
        } else {
            // If this item is the current item we just return the scrolled amount in relation to the previous current offset.
            return currentOffset - scrolledOffset
        }
    }

    func targetOffset() -> CGFloat {
        // Get the current scroll offset. This is calculated by subtracting the old scroll offset from the current one.
        let currentScrollOffset = -(scrolledOffset - currentOffset)

        // Check to see if the user has scrolled enough as to warant an element change.
        guard abs(currentScrollOffset) > minScroll else {
            return self.currentOffset
        }

        // Check to see if the user is scrolling up or down in order to update the currently selected index.
        if scrolledOffset < currentOffset, currentIndex < (items.count - 1) {
            self.currentIndex += 1
        } else if scrolledOffset > currentOffset, currentIndex > 0 {
            self.currentIndex -= 1
        }

        // We calculate the current offset from the top of the VStack. We do this in order to correctly calculate the offset in the VStack coordinate space.
        let currentOffset = (Constants.liveSize / 2) + CGFloat(self.currentIndex) * (Constants.liveSize * 0.6) + (CGFloat(self.currentIndex) * Constants.spacing)

        // The target offset will be the difference between the middle of the content and the current offset.
        return self.midContentOffset - currentOffset
    }

    func initialParams() -> (index: Int, offset: CGFloat, contentHeight: CGFloat) {
        // Calculate total height of the VStack
        let contentHeight = CGFloat(items.count - 1) * (Constants.liveSize * Constants.scaleFactor) + Constants.liveSize + CGFloat(items.count - 1) * Constants.spacing

        // Get the index of the live item. If there are multiple live items (wrong data) then we take the first one.
        let liveIndex = items.firstIndex(where: { $0.isLive }) ?? 0

        // Return the live index and the offset of the live item within the VStack coordinate space (In this space an offset of 0 means the VStack is centered on the screen)
        return (liveIndex, contentHeight / 2 - (Constants.liveSize * Constants.scaleFactor) * CGFloat(liveIndex) - Constants.spacing * CGFloat(liveIndex) - Constants.liveSize / 2, contentHeight)
    }
}

enum Constants {
    static let liveSize: CGFloat = 300.0
    static let normalSize: CGFloat = 200.0
    static let spacing: CGFloat = 24.0
    static let cornerRadius: CGFloat = 24.0
    static let benchmark: CGFloat = 90 + 150.0 + 24.0
    static let scaleFactor: CGFloat = 0.6
    static let minScrollFactor: CGFloat = 60.0
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
