( Donkey-Kong game for the ZTH1 
  
  By S. Morel, Zthorus-Labs

  Date          Action
  ----          ------
  2021-12-02    First release on GitHub
) 

( Redefine lowercase characters: a= beam element, b = ladder element,
  c to l = Kong, m and n = Princess, o to q = burning barrel )

data $1f84 $ffc3a599a5c3ff00ff81ff81ff81ff81 ( a b )
data $1f8c $070b1517180f3f7ff8f0e0e0e4fe7c183f3f3e3c3c3c7cfc ( c d e )
data $1f98 $e0d0a8e818f0fcfe1f0f0707277f3e18fcfc7c3c3c3c3e3f ( f g h )
data $1fa4 $070f0b0f0f070f1f3f7f7fffffffff7f ( i j )
data $1fac $e0d07880f8c0e0f0f8bc3c1e1e1ebc80 ( k l )
data $1fb4 $00001e3b7e4c0e16121d1e1e3e7e1a1f ( m n )
data $1fbc $020a466a6a7afaffffff15555514ffff ( o p )
data $1fc4 $405044d4d6deffff ( q ) 

( Sprite bitmaps - horizontally reversed - )

( Mario is made of two sprites: 0= top, 1= bottom )

data mLTop $787e687c30785858
data mRTop $1e7e163e0c1e1a1a
data mLBottom $487468686868687c48747868ccccccee487478cccc85874248747868ccccccee 
data mRBottom $122e16161616163e122e1e1633333377122e1e222241e142122e1e1633333377 
data mOnLadTop $3c3cbc98fefe7e7e3c3c3d197f7f7e7e
data mOnLadBottom $7e7e6666666060607e7e666666060606
 ( data barrelSide $00000000183c3c18
data barrelFront $000000003c7e7e3c )
data barrelSide $0000001c3e3e3e1c
data barrelFront $0000007effffff7e

data ladderLevels $000e000a000a0006
data xLadders     $0016000a00010016
data LadderProbs  $0001000000010001
data xBarrels     $0030006000300080
data yBarrels     $0010003000500070
data barrelLevels $0006000a000e0012
data barrelStates $0000000000000000
data yBarrelEnds  $0000000000000000

( following used to restore barrel parameters after each Mario's death )
data barMem     $00300060003000800010003000500070
data barMem2    $0006000a000e00120000000000000000

: drawStage1
  var xLad var yLad
  ( set colors by addressing sys-var $1873 )
  $0a00 $1873 !
  6 6 at
  3 0 do
    i 4 * 3 + 0 at ." aaaaaaaaaaaaaaaaaaaaaaa" 
  loop
  $0b00 $1873 !
  3 0 do
    ladderLevels i + @ yLad !
    xLadders i + @ xLad !
    4 1 do
      yLad @ xLad @ at ." b"
      yLad @ 1- yLad !
    loop
  loop 
  $0600 $1873 !
  0 2 at ." cf" 1 2 at ." dg" 2 2 at ." eh" 
  $0900 $1873 ! 0 6 at ." m" $0400 $1873 ! 1 6 at ." n"  
  $0900 $1873 ! 2 6 at ." bb"
  $0200 $1873 ! 13 0 at ." o" $0300 $1873 ! 14 0 at ." p"  
  0 18 at ." 0" 0 23 at ." 3" 
;

: pause
  8000 0 do i loop
;

: main
  var xm var ym ( Mario's coordinates )
  var mState    ( Mario's state: 0= walking, 1= jumping, 2= on ladder )
  var mDir      ( Mario's horizontal motion direction: -1= left, +1= right )
  var mDir2     ( Mario's body direction: -1= left, +1= right )
  var mLevel    ( Mario's level, compared to ladder bottom )
  var mJump     ( Mario's jump phase )
  var mJump2    ( Mario's jump speed control )
  var xLad      ( coordinate of nearest ladder )
  var yTop      ( vertical position of top of ladder climbed by Mario )
  var yBottom   ( vertical position of bottom of ladder climbed by Mario )
  var LevelUp   ( next level for Mario after reaching top of ladder )
  var LevelDown ( next level for Mario after reaching bottom of ladder )

  var xBar var yBar ( barrel coordinates )
  var barLevel      ( barrel Level )
  var barState      ( barrel state: 0= rolling on beam, 1= falling from lader )
  var ybarEnd       ( y-coordinate when barrel will reach bottom of ladder )
  var spriteNum     ( sprite number of barrel )
  var kongThrow     ( Kong throwing barrel phase )
  var firePh        ( phase of fire in burning barrel )
  var joy           ( joystick state )
  var rand          ( random variable )
  var score
  var lives
  var bailout       ( if 1, quit the main loop )
  var n  

  begin

    ( beginning of game )

    0 score !
    3 lives !
    $0700 $1873 ! cls drawStage1

    begin

      ( beginning of new Mario's life )

      10 xm ! 104 ym ! 1 mDir ! 0 mState ! 14 mLevel ! 
      1 mDir2 !
      9 0 colorsprite 5 1 colorsprite
      mRTop 0 defsprite
      mRBottom 1 defsprite
      ym @ xm @ 0 putsprite
      ym @ 8 + xm @ 1 putsprite
      2 2 colorsprite 2 3 colorsprite 2 4 colorsprite 2 5 colorsprite
      barrelSide 2 defsprite
      barrelSide 3 defsprite
      barrelSide 4 defsprite
      barrelSide 5 defsprite

      ( set/restore barrel parameters )

      15 0 do 
        barMem i + @ xBarrels i + !
      loop 
      3 0 do
        yBarrels i + @ xBarrels i + @ 2 i + putsprite
      loop

      0 kongThrow !
      0 firePh !

      ( joystick anti-bounce. Otherwise sprite collision right after
        beginning of a new game that has started with joystick motion.
        Probably a race-condition related to ZTH1 code execution faster
        than video frame generation in which the collision flag is updated ) 
      begin
        joystick 15
      until= 

      ( wait for joystick move to create random number seed )
      0 rand !
      begin
        rand @ 1+ rand !
        joystick 15
      until!=

      0 bailout !

      ( main loop )

      begin

        ( manage Mario's motion )

        joystick joy !
        mState @ 0
        ( Mario walking )
        if=
          0 mDir !
          joy @ 1 and 0
          ( move right )
          if= 1 mDir ! 1 mDir2 ! then
          joy @ 2 and 0
          ( move left ) 
          if= -1 mDir ! -1 mDir2 ! then
          joy @ 8 and 0
          ( move up )
          if=
            3 0 do
              ladderLevels i + @ mLevel @
              if=
                xLadders i + @ 2* 2* 2* xLad !
                ( check if Mario close to bottom of ladder )
                xm @ xLad @ 1- 1- < xm @ xLad @ 1+ 1+ > and
                if
                  2 mState !
                  xLad @ xm !
                  mLevel @ LevelDown !
                  4 mLevel @ - LevelUp !
                  ym @ yBottom !
                  32 ym @ - yTop !
                  0 mDir !
                then
              then
            loop
            mState @ 2 
            if!=
              ( jump )
              1 mState !
              0 mJump !
              0 mJump2 !
            then
          then
          joy @ 4 and 0
          ( move down )
          if=
            3 0 do
              ladderLevels i + @ 4 swap - mLevel @
              if=
                xLadders i + @ 8 * xLad !
                ( check if Mario close to top of ladder )
                xm @ xLad @ 1- 1- < xm @ xLad @ 1+ 1+ > and
                if
                  2 mState !
                  xLad @ xm ! 0 mDir !
                  mLevel @ LevelUp !
                  mLevel @ 4 + LevelDown !
                  ym @ yTop !
                  ym @ 32 + yBottom ! 
                  0 mDir !
                then
              then
            loop
          then
        then
        mState @ 1
        ( Mario jumping )
        if=
          mJump2 @ not mJump2 !
          mJump2 @ 0
          if<
            mJump @ 8
            if> ym @ 1- ym ! else ym @ 1+ ym ! then
            mJump @ 1+ mJump !
            mJump @ 16
            if= 0 mState ! then
          then
        then
        mState @ 2
        ( Mario climbing ladder up or down )
        if= 
          joy @ 8 and 0
          ( move up )
          if=
            ym @ 1- ym !
            ym @ yTop @ 
            if=
              0 mState !
              1 mDir2 !
              LevelUp @ mLevel !
            then
          then
          joy @ 4 and 0
          ( move down )
          if= 
            ym @ 1+ ym !
            ym @ yBottom @ 
            if=
              0 mState !
              1 mDir2 !
              LevelDown @ mLevel !
            then
          then
        then
        xm @ mDir @ + xm !
        ( horizontal limits )
        xm @ 1 
        if> 1 xm ! then
        xm @ 176 
        if< 176 xm ! then
        ( draw Mario )
        mState @ 0 
        if=
          mDir2 @ 1
          if=
            mRTop 0 defsprite
            xm @ 3 and 2* 2* mRBottom + 1 defsprite
          then
          mDir @ -1
          if=
            mLTop 0 defsprite
            xm @ 3 and 2* 2* mLBottom + 1 defsprite
          then
        then
        mState @ 1
        if=
          mDir2 @ 1
          if=
            mRTop 0 defsprite
            8 mRBottom + 1 defsprite
          then
          mDir2 @ -1
          if=
            mLTop 0 defsprite
            8 mLBottom + 1 defsprite
          then
        then
        mState @ 2
        if=
          ym @ 1 and
          if
            mOnLadTop 0 defsprite
            mOnLadBottom 1 defsprite
          else
            mOnLadTop 4 + 0 defsprite
            mOnLadBottom 4 + 1 defsprite
          then
        then  
        ym @ xm @ 0 putsprite
        ym @ 8 + xm @ 1 putsprite

        ( manage barrel motions )

        3 0 do
          i 2 + spriteNum !
          xBarrels i + @ xBar !
          yBarrels i + @ yBar !
          barrelLevels i + @ barLevel !
          barrelStates i + @ barState !
          yBarrelEnds i + @ yBarEnd !

          barState @ 0
          if=
            ( barrel rolling on beam )
            barLevel @ 6
            if= xBar @ 1+ xBar ! then
            barLevel @ 10 
            if= xBar @ 1- xBar ! then
            barLevel @ 14 
            if= xBar @ 1+ xBar ! then
            barLevel @ 18 
            if= xBar @ 1- xBar ! then
            ( check if barrel at top of a ladder )
            3 0 do
              ladderLevels i + @ barLevel @
              if=
                xLadders i + @ 2* 2* 2* xBar @
                if=
                  ladderProbs i + @ 1
                  ( barrel always falling from this ladder )
                  if=
                     1 barState !
                     yBar @ 32 + yBarEnd !
                     barrelFront spriteNum @ defsprite
                  else
                    ( toss to decide if barrel will fall from ladder )
                    rand @ 250 and n !
                    n @ 250 = n @ 0 = or
                    if
                      rand @ 2/ $8000 or rand !
                    else
                      rand @ 2/ rand !
                    then
                    rand @ 1 and 0
                    if=
                      1 barState !
                      yBar @ 32 + yBarEnd !
                      barrelFront spriteNum @ defsprite
                    then
                  then 
                then
              then
            loop
          else
            ( barrel falling from a ladder )
            yBar @ 1+ yBar !
            yBarEnd @ yBar @
            if= 
              barLevel @ 4 + barLevel ! 
              0 barState !
              barrelSide spriteNum @ defsprite
            then
          then
          xBar @ 1 = yBar @ 112 = and 
          ( if barrel reaches end of lowest beam )
          if 
            30 xBar ! 16 yBar !
            6 barLevel !
            10 score @ + score !
            $0300 $1873 ! 0 18 at score @ .
            $0600 $1873 ! 0 2 at ." ik" 1 2 at ." jl"
            50 kongThrow !
          then
          yBar @ xBar @ spriteNum @ putsprite
          xBar @ xBarrels i + !
          yBar @ yBarrels i + !
          barState @ barrelStates i + !
          barLevel @ barrelLevels i + !
          yBarEnd @ yBarrelEnds i + !
        loop

        ( various animations )
 
        kongThrow @ 0
        if!=
          kongThrow @ 1- kongThrow !
        then
        kongThrow @ 1
        if=
          $0600 $1873 ! 0 2 at ." cf" 1 2 at ." dg"
          0 kongThrow !
        then
        fireph @ 1+ firePh !
        firePh @ 7 and 0
        if=
          $0200 $1873 ! 13 0 at ." o"
        then
        firePh @ 7 and 4 
        if=
          $0200 $1873 ! 13 0 at ." q"
        then
        
        pause
  
        ( check if Mario has been hit by a barrel )
        $1824 @ 0
        if!= 1 bailout !  then 
        ( check if Mario reached the top )
        ym @ 8 = xm @ 70 = and
        if 1 bailout ! then 
        bailout @ 
      until
       
      $1824 @ 0
      if!=
        ( death flashing )
        ( known compiler bug: cannot call a word containing a do-loop
          from inside a do-loop )
        20 0 do
          $ff80 $1800 !
          10000 0 do i loop   
          $0080 $1800 !
          10000 0 do i loop   
        loop
        lives @ 1- lives !
        $0300 $1873 ! 0 23 at lives @ .
        ( wait for player to release joystick )
      else
        ( win ! )
        20 0 do
          $ff80 $1801 ! $ff80 $1802 !
          10000 0 do i loop   
          $0080 $1801 ! $0080 $1802 !
          10000 0 do i loop   
        loop
        score @ 1000 + score !
        $0300 $1873 ! 0 18 at score @ .
      then
      ( wait for player to release joystick )
      begin
        joystick 15
      until=
  
      lives @ 0
    until=

    $0300 $1873 5 7 at ." GAME-OVER"
    begin
      joystick 15
    until!=
    0
  until
;
