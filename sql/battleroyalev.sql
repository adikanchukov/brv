SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";

CREATE TABLE `coords` (
  `id` int(11) NOT NULL,
  `x` float NOT NULL,
  `y` float NOT NULL,
  `z` float NOT NULL
) DEFAULT CHARSET=utf8mb4;

CREATE TABLE `games` (
  `id` int(11) NOT NULL,
  `safezones` text NOT NULL,
  `created` datetime NOT NULL,
  `finished` datetime DEFAULT NULL,
  `wid` int(11) DEFAULT NULL
) DEFAULT CHARSET=utf8mb4;

CREATE TABLE `players` (
  `id` int(11) NOT NULL,
  `steamid` varchar(50) NOT NULL,
  `role` varchar(10) NOT NULL,
  `name` varchar(50) NOT NULL,
  `skin` varchar(50) DEFAULT NULL,
  `created` datetime DEFAULT NULL,
  `last_login` datetime DEFAULT NULL,
  `status` tinyint(1) NOT NULL
) DEFAULT CHARSET=utf8mb4;

CREATE TABLE `players_stats` (
  `pid` int(11) NOT NULL,
  `gid` int(11) NOT NULL,
  `weapon` varchar(50) NOT NULL,
  `spawn` varchar(255) NOT NULL,
  `rank` int(3) NOT NULL,
  `kills` int(3) NOT NULL
) DEFAULT CHARSET=utf8mb4;


ALTER TABLE `coords`
  ADD PRIMARY KEY (`id`);

ALTER TABLE `games`
  ADD PRIMARY KEY (`id`),
  ADD KEY `FK_WID` (`wid`);

ALTER TABLE `players`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `steamid` (`steamid`);

ALTER TABLE `players_stats`
  ADD PRIMARY KEY (`pid`,`gid`),
  ADD KEY `FK_GID` (`gid`);


ALTER TABLE `coords`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `games`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `players`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `games`
  ADD CONSTRAINT `FK_WID` FOREIGN KEY (`wid`) REFERENCES `players` (`id`);

ALTER TABLE `players_stats`
  ADD CONSTRAINT `FK_GID` FOREIGN KEY (`gid`) REFERENCES `games` (`id`),
  ADD CONSTRAINT `FK_PID` FOREIGN KEY (`pid`) REFERENCES `players` (`id`);
COMMIT;
