SELECT Win_Loss.*, p0_groups_left.count, p1_groups_left.count
FROM ( 
    SELECT Games.game_id, 
           Games.player_0, 
           Games.player_1, 
           Games.win_state, 
           IF( Scores.p0_score > Scores.p1_score, 0, 1 )
    FROM Games
    INNER JOIN Scores
    ON Games.game_id    = Scores.game_id AND
       Games.turn_count = Scores.turn_num 
    WHERE Games.win_state = 1
    UNION
    SELECT Games.game_id, 
           Games.player_0, 
           Games.player_1, 
           Games.win_state, 
           IF( Node_Knowledge.control_percent = -100, 1, 0 )
    FROM Games
    INNER JOIN Node_Knowledge
    ON Games.turn_count = Node_Knowledge.turn_num AND
       Games.game_id    = Node_Knowledge.game_id
    WHERE Games.win_state = 2 AND
          Node_Knowledge.node_id = 1 AND
          Node_Knowledge.player = 1
    UNION
    SELECT Games.game_id, 
           Games.player_0, 
           Games.player_1, 
           Games.win_state, 
           -1
    FROM Games
    WHERE Games.win_state = 3 ) as Win_Loss 
INNER JOIN ( 
    SELECT Games.game_id,
           Count(*) as count
    FROM Games
    INNER JOIN Groups
    ON Games.game_id = Groups.game_id
    WHERE ( Games.game_id, Groups.group_id ) NOT IN(
        SELECT Disband.game_id,
               Disband.group_id
        FROM Disband
    )
    AND Groups.player = 0
    GROUP BY Games.game_id
) as p0_groups_left
ON p0_groups_left.game_id = Win_Loss.game_id
INNER JOIN (
    SELECT Games.game_id,
           Count(*) as count
    FROM Games
    INNER JOIN Groups
    ON Games.game_id = Groups.game_id
    WHERE ( Games.game_id, Groups.group_id ) NOT IN(
        SELECT Disband.game_id,
               Disband.group_id
        FROM Disband
    )
    AND Groups.player = 1
    GROUP BY Games.game_id
) as p1_groups_left
ON p1_groups_left.game_id = Win_Loss.game_id
INTO OUTFILE '/var/lib/mysql-files/groups_remaining.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY ''
LINES TERMINATED BY '\n';