//
//  ViewController.swift
//  collection-view-layout-practice
//
//  Created by jinsei_shima on 2021/02/04.
//

import UIKit
import EasyPeasy

class ViewController: UIViewController, UICollectionViewDataSource {

  let collectionView: UICollectionView = .init(frame: .zero, collectionViewLayout: MessageCollectionLayout())

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .white

    collectionView.backgroundColor = .white
    collectionView.dataSource = self
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

}

// https://gist.github.com/GeekTree0101/12ea397c5142c97d99b24494774a9557

public final class MessageCollectionLayout : UICollectionViewFlowLayout {

  private var offset: CGFloat = 0.0
  private var visibleAttributes: [UICollectionViewLayoutAttributes]?
  private var isPrepend: Bool = false

  override public func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
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

    print("xxx: finalize collectionView updates", collectionView?.contentOffset)

    guard let collectionView = self.collectionView, isPrepend else { return }
    // Adjust Content Offset
    let newContentOffset = CGPoint(x: collectionView.contentOffset.x,
                                   y: collectionView.contentOffset.y + self.offset)
    collectionView.contentOffset = newContentOffset
    CATransaction.commit()
  }

  public override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {

    print("xxx: target content offset", proposedContentOffset)

    return proposedContentOffset
  }

}

