//
//  ViewController.swift
//  collection-view-layout-practice
//
//  Created by jinsei_shima on 2021/02/04.
//

import UIKit
import EasyPeasy

final class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDataSourcePrefetching {

  private let collectionView: UICollectionView = .init(frame: .zero, collectionViewLayout: MessageCollectionLayout4())

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .white

    collectionView.backgroundColor = .white
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.prefetchDataSource = self
    collectionView.isPrefetchingEnabled = true
    collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
    collectionView.alwaysBounceVertical = true

    if let collectionViewLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
      collectionViewLayout.itemSize = .init(width: UIScreen.main.bounds.width, height: 80)
    }

    view.addSubview(collectionView)
    collectionView.easy.layout(Edges())

    do {
      let addButton = UIButton(type: .contactAdd, primaryAction: UIAction.init(handler: { (action) in

        self.collectionView.performBatchUpdates {
          self.items.append("ggggg")
          self.collectionView.insertItems(at: [IndexPath(item: self.items.endIndex-1, section: 0)])
        } completion: { (completion) in

        }

      }))
      view.addSubview(addButton)
      addButton.easy.layout(Left(48), Bottom(80))
    }

    do {

      let addButton = UIButton(type: .contactAdd, primaryAction: UIAction.init(handler: { (action) in

        self.collectionView.performBatchUpdates {
          self.items.insert("aaaaa", at: 0)
          self.collectionView.insertItems(at: [IndexPath(item: 0, section: 0)])
        } completion: { (completion) in

        }

      }))
      view.addSubview(addButton)
      addButton.easy.layout(Right(48), Bottom(80))

    }
  }

  var items = ["a", "b", "b", "b", "b", "b", "b", "b"]

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    items.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)

    cell.contentView.subviews.forEach { $0.removeFromSuperview() }

    let label = UILabel()
    label.text = items[indexPath.item]
    label.textColor = .darkText

    cell.contentView.addSubview(label)
    label.easy.layout(Center())
    return cell
  }

  func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {

  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {


    func makeString() -> String {
       [
        "ccc",
        "bbbbbbbbb",
        "aaaaaaaa",
        "aakkkkkkkkkkk",
        "mmmmmmm",
        "jjj",
        "eee",
        "sssssssss",
        "nnnnnnnnnnnnnnnnnn",
       ].randomElement()!
    }

    if scrollView.contentOffset.y < 0 {

      self.collectionView.performBatchUpdates {
        self.items.insert(makeString(), at: 0)
        self.collectionView.insertItems(at: [IndexPath(item: 0, section: 0)])
      } completion: { (completion) in

      }

    }

    if scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.bounds.height {

      self.collectionView.performBatchUpdates {
        self.items.append(makeString())
        self.collectionView.insertItems(at: [IndexPath(item: self.items.endIndex-1, section: 0)])
      } completion: { (completion) in

      }

    }
  }

}


// https://gist.github.com/GeekTree0101/12ea397c5142c97d99b24494774a9557

final class MessageCollectionLayout2 : UICollectionViewFlowLayout {

  private var offset: CGFloat = 0.0
  private var visibleAttributes: [UICollectionViewLayoutAttributes]?
  private var isPrepend: Bool = false

  override public func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {

    print("xxx: layout attributes for element")

    // Reset offset and prepend scope
    visibleAttributes = super.layoutAttributesForElements(in: rect)
    offset = 0.0
    isPrepend = false
    return visibleAttributes
  }

  override public func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {

    print("xxx: prepare")

    guard let collectionView = self.collectionView else { return }
    guard let visibleAttributes = self.visibleAttributes else { return }

    // Calculate Bottom and Top Visible Item Count
    var bottomVisibleItem = -Int.max
    var topVisibleItem = Int.max
    var containerHeight: CGFloat = collectionView.frame.size.height
    containerHeight -= collectionView.contentInset.top
    containerHeight -= collectionView.contentInset.bottom
    let container = CGRect(x: collectionView.contentOffset.x,
                           y: collectionView.contentOffset.y,
                           width: collectionView.frame.size.width,
                           height: containerHeight)
    for attributes in visibleAttributes {
      if attributes.frame.intersects(container) {
        let item = attributes.indexPath.item

        if item < topVisibleItem {
          topVisibleItem = item
        }

        if item > bottomVisibleItem {
          bottomVisibleItem = item
        }
      }
    }

    super.prepare(forCollectionViewUpdates: updateItems)

    // Check: Initial Load or Load More
    let isInitialLoading: Bool = bottomVisibleItem + topVisibleItem == 0

    // Chack: Pre-Append or Append
    if updateItems.first?.indexPathAfterUpdate?.item ?? -1 == 0,
       updateItems.first?.updateAction == .insert,
       !isInitialLoading {
      self.isPrepend = true
    } else {
      return
    }

    // Calculate Offset
    offset = updateItems
      .filter { $0.updateAction == .insert }
      .compactMap { $0.indexPathAfterUpdate }
      .filter { topVisibleItem + updateItems.count > $0.item }
      .compactMap { self.layoutAttributesForItem(at: $0) }
      .map { $0.size.height + self.minimumLineSpacing }
      .reduce(0.0, { $0 + $1 })

    let contentHeight = collectionView.contentSize.height
    var frameHeight = collectionView.frame.size.height
    frameHeight -= collectionView.contentInset.top
    frameHeight -= collectionView.contentInset.bottom

    guard contentHeight + offset > frameHeight else {
      // Exception
      self.isPrepend = false
      return
    }
    CATransaction.begin()
    CATransaction.setDisableActions(true)
  }

  override public func finalizeCollectionViewUpdates() {

    print("xxx: finalize collectionView updates", collectionView?.contentOffset, offset)

    guard let collectionView = self.collectionView, isPrepend else { return }
    // Adjust Content Offset
    let newContentOffset = CGPoint(x: collectionView.contentOffset.x,
                                   y: collectionView.contentOffset.y + offset)
    collectionView.contentOffset = newContentOffset
    CATransaction.commit()
  }

  public override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {

    print("xxx: target content offset", proposedContentOffset)

    return proposedContentOffset
  }

}


// https://gist.github.com/jochenschoellig/04ffb26d38ae305fa81aeb711d043068
class MessageCollectionLayout3: UICollectionViewFlowLayout {

  private var topMostVisibleItem    =  Int.max
  private var bottomMostVisibleItem = -Int.max

  private var offset: CGFloat = 0.0
  private var visibleAttributes: [UICollectionViewLayoutAttributes]?

  private var isInsertingItemsToTop    = false
  private var isInsertingItemsToBottom = false


  override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {

    // Reset each time all values to recalculate them
    // ════════════════════════════════════════════════════════════

    // Get layout attributes of all items
    visibleAttributes = super.layoutAttributesForElements(in: rect)

    // Erase offset
    offset = 0.0

    // Reset inserting flags
    isInsertingItemsToTop    = false
    isInsertingItemsToBottom = false

    return visibleAttributes
  }

  override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {

    // Check where new items get inserted
    // ════════════════════════════════════════════════════════════

    // Get collection view and layout attributes as non-optional object
    guard let collectionView = self.collectionView       else { return }
    guard let visibleAttributes = self.visibleAttributes else { return }


    // Find top and bottom most visible item
    // ────────────────────────────────────────────────────────────

    bottomMostVisibleItem = -Int.max
    topMostVisibleItem    =  Int.max

    let container = CGRect(x: collectionView.contentOffset.x,
                           y: collectionView.contentOffset.y,
                           width:  collectionView.frame.size.width,
                           height: (collectionView.frame.size.height - (collectionView.contentInset.top + collectionView.contentInset.bottom)))

    for attributes in visibleAttributes {

      // Check if cell frame is inside container frame
      if attributes.frame.intersects(container) {
        let item = attributes.indexPath.item
        if item < topMostVisibleItem    { topMostVisibleItem    = item }
        if item > bottomMostVisibleItem { bottomMostVisibleItem = item }
      }
    }


    // Call super after first calculations
    super.prepare(forCollectionViewUpdates: updateItems)


    // Calculate offset of inserting items
    // ────────────────────────────────────────────────────────────

    var willInsertItemsToTop    = false
    var willInsertItemsToBottom = false

    // Iterate over all new items and add their height if they go inserted
    for updateItem in updateItems {
      switch updateItem.updateAction {
      case .insert:
        if topMostVisibleItem + updateItems.count > updateItem.indexPathAfterUpdate!.item {

          if let newAttributes = self.layoutAttributesForItem(at: updateItem.indexPathAfterUpdate!) {

            offset += (newAttributes.size.height + self.minimumLineSpacing)
            willInsertItemsToTop = true
          }

        } else if bottomMostVisibleItem <= updateItem.indexPathAfterUpdate!.item {

          if let newAttributes = self.layoutAttributesForItem(at: updateItem.indexPathAfterUpdate!) {

            offset += (newAttributes.size.height + self.minimumLineSpacing)
            willInsertItemsToBottom = true
          }
        }

      case.delete:
        // TODO: Handle removal of items
        break

      default:
        break
      }
    }


    // Pass on information if items need more than one screen
    // ────────────────────────────────────────────────────────────

    // Just continue if one flag is set
    if willInsertItemsToTop || willInsertItemsToBottom {

      // Get heights without top and bottom
      let collectionViewContentHeight = collectionView.contentSize.height
      let collectionViewFrameHeight   = collectionView.frame.size.height - (collectionView.contentInset.top + collectionView.contentInset.bottom)

      // Continue only if the new content is higher then the frame
      // If it is not the case the collection view can display all cells on one screen
      if collectionViewContentHeight + offset > collectionViewFrameHeight {

        if willInsertItemsToTop {
          CATransaction.begin()
          CATransaction.setDisableActions(true)
          isInsertingItemsToTop = true

        } else if willInsertItemsToBottom {
          isInsertingItemsToBottom = true
        }
      }
    }
  }

  override func finalizeCollectionViewUpdates() {

    // Set final content offset with animation or not
    // ════════════════════════════════════════════════════════════

    // Get collection view as non-optional object
    guard let collectionView = self.collectionView else { return }

    if isInsertingItemsToTop {

      // Calculate new content offset
      let newContentOffset = CGPoint(x: collectionView.contentOffset.x,
                                     y: collectionView.contentOffset.y + offset)

      // Set new content offset without animation
      collectionView.contentOffset = newContentOffset

      // Commit/end transaction
      CATransaction.commit()

    } else if isInsertingItemsToBottom {

      // Calculate new content offset
      // Always scroll to bottom
      let newContentOffset = CGPoint(x: collectionView.contentOffset.x,
                                     y: collectionView.contentSize.height + offset - collectionView.frame.size.height + collectionView.contentInset.bottom)

      // Set new content offset with animation
      collectionView.setContentOffset(newContentOffset, animated: true)
    }
  }
}

final class MessageCollectionLayout4: UICollectionViewFlowLayout {

  private var topMostVisibleItem = Int.max

  private var offset: CGFloat = 0.0
  private var visibleAttributes: [UICollectionViewLayoutAttributes]?

  private var isInsertingItemsToTop = false

  override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {

    // Reset each time all values to recalculate them
    // ════════════════════════════════════════════════════════════

    // Get layout attributes of all items
    visibleAttributes = super.layoutAttributesForElements(in: rect)

    // Erase offset
    offset = 0.0

    // Reset inserting flags
    isInsertingItemsToTop = false

    return visibleAttributes
  }

  override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {

    // Check where new items get inserted
    // ════════════════════════════════════════════════════════════

    // Get collection view and layout attributes as non-optional object
    guard let collectionView = self.collectionView else { return }
    guard let visibleAttributes = self.visibleAttributes else { return }


    // Find top and bottom most visible item
    // ────────────────────────────────────────────────────────────

    topMostVisibleItem = Int.max

    let container = CGRect(
      x: collectionView.contentOffset.x,
      y: collectionView.contentOffset.y,
      width: collectionView.frame.size.width,
      height: (collectionView.frame.size.height - (collectionView.contentInset.top + collectionView.contentInset.bottom))
    )

    for attributes in visibleAttributes {

      // Check if cell frame is inside container frame
      if attributes.frame.intersects(container) {
        let item = attributes.indexPath.item
        if item < topMostVisibleItem { topMostVisibleItem = item }
      }
    }


    // Call super after first calculations
    super.prepare(forCollectionViewUpdates: updateItems)


    // Calculate offset of inserting items
    // ────────────────────────────────────────────────────────────

    var willInsertItemsToTop = false

    // Iterate over all new items and add their height if they go inserted
    for updateItem in updateItems {
      switch updateItem.updateAction {
      case .insert:
        if topMostVisibleItem + updateItems.count > updateItem.indexPathAfterUpdate!.item {

          if let newAttributes = layoutAttributesForItem(at: updateItem.indexPathAfterUpdate!) {

            offset += (newAttributes.size.height + minimumLineSpacing)
            willInsertItemsToTop = true
          }

        }

      case.delete:
        // TODO: Handle removal of items
        break

      default:
        break
      }
    }


    // Pass on information if items need more than one screen
    // ────────────────────────────────────────────────────────────

    // Just continue if one flag is set
    if willInsertItemsToTop {

      // Get heights without top and bottom
      let collectionViewContentHeight = collectionView.contentSize.height
      let collectionViewFrameHeight = collectionView.frame.size.height - (collectionView.contentInset.top + collectionView.contentInset.bottom)

      // Continue only if the new content is higher then the frame
      // If it is not the case the collection view can display all cells on one screen
      if collectionViewContentHeight + offset > collectionViewFrameHeight {

        if willInsertItemsToTop {
          CATransaction.begin()
          CATransaction.setDisableActions(true)
          isInsertingItemsToTop = true
        }
      }
    }
  }

  override func finalizeCollectionViewUpdates() {

    // Set final content offset with animation or not
    // ════════════════════════════════════════════════════════════

    // Get collection view as non-optional object
    guard let collectionView = self.collectionView else { return }

    if isInsertingItemsToTop {

      // Calculate new content offset
      let newContentOffset = CGPoint(
        x: collectionView.contentOffset.x,
        y: collectionView.contentOffset.y + offset
      )

      // Set new content offset without animation
      collectionView.contentOffset = newContentOffset

      // Commit/end transaction
      CATransaction.commit()

    }
  }
}
