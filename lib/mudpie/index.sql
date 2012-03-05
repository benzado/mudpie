CREATE TABLE `files` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  `path` TEXT NOT NULL UNIQUE ON CONFLICT REPLACE,
  `size` INTEGER NOT NULL,
  `mtime` INTEGER NOT NULL,
  `ymf_len` INTEGER,
  `url` TEXT NOT NULL,
  `date` INTEGER NOT NULL,
  `collection_name` TEXT
);

CREATE TABLE `metadata` (
  `file_id` INTEGER NOT NULL,
  `key` TEXT NOT NULL,
  `index` INTEGER,
  `value` TEXT NOT NULL
);
CREATE UNIQUE INDEX `fko` ON `metadata` (`file_id`,`key`,`index`);
