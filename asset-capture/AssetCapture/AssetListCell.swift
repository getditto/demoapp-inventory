import UIKit

final class AssetListCell: UITableViewCell {

    static let reuseID = "AssetListCell"
    static let height: CGFloat = 80

    // MARK: - Subviews

    private let thumbnailView: UIImageView = {
        let iv = UIImageView()
        iv.backgroundColor = UIColor.secondarySystemBackground
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 8
        iv.layer.masksToBounds = true
        iv.image = UIImage(systemName: "camera.fill")
        iv.tintColor = .systemGray3
        return iv
    }()

    private let nsnLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.boldSystemFont(ofSize: 16)
        return l
    }()

    private let conditionBadge: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        l.textColor = .white
        l.textAlignment = .center
        l.layer.cornerRadius = 9
        l.layer.masksToBounds = true
        return l
    }()

    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        return l
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        [thumbnailView, nsnLabel, conditionBadge, dateLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            thumbnailView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            thumbnailView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thumbnailView.widthAnchor.constraint(equalToConstant: 56),
            thumbnailView.heightAnchor.constraint(equalToConstant: 56),

            nsnLabel.leadingAnchor.constraint(equalTo: thumbnailView.trailingAnchor, constant: 12),
            nsnLabel.topAnchor.constraint(equalTo: thumbnailView.topAnchor, constant: 6),
            nsnLabel.trailingAnchor.constraint(equalTo: conditionBadge.leadingAnchor, constant: -8),

            conditionBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            conditionBadge.centerYAnchor.constraint(equalTo: nsnLabel.centerYAnchor),
            conditionBadge.widthAnchor.constraint(equalToConstant: 88),
            conditionBadge.heightAnchor.constraint(equalToConstant: 20),

            dateLabel.leadingAnchor.constraint(equalTo: nsnLabel.leadingAnchor),
            dateLabel.topAnchor.constraint(equalTo: nsnLabel.bottomAnchor, constant: 4),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Configure

    func configure(asset: Asset) {
        nsnLabel.text = asset.nsn.isEmpty ? "(No NSN)" : asset.nsn
        dateLabel.text = asset.formattedDate

        let condition = asset.conditionEnum
        conditionBadge.text = condition.rawValue
        conditionBadge.backgroundColor = condition.color

        if let img = asset.photo {
            thumbnailView.image = img
            thumbnailView.tintColor = nil
            thumbnailView.backgroundColor = .black
        } else {
            thumbnailView.image = UIImage(systemName: "camera.fill")
            thumbnailView.tintColor = .systemGray3
            thumbnailView.backgroundColor = UIColor.secondarySystemBackground
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailView.image = UIImage(systemName: "camera.fill")
        thumbnailView.tintColor = .systemGray3
        thumbnailView.backgroundColor = UIColor.secondarySystemBackground
        nsnLabel.text = nil
        dateLabel.text = nil
        conditionBadge.text = nil
        conditionBadge.backgroundColor = nil
    }
}
