<chart>
symbol=USDCHF
period=60
digits=5

leftpos=13564
scale=4
graph=1
fore=0
grid=0
volume=0
ohlc=0
askline=0
days=0
descriptions=1
scroll=1
shift=1
shift_size=10

fixed_pos=620
window_left=0
window_top=0
window_right=1304
window_bottom=1032
window_type=3

background_color=16316664
foreground_color=0
barup_color=30720
bardown_color=210
bullcandle_color=30720
bearcandle_color=210
chartline_color=11119017
volumes_color=30720
grid_color=14474460
askline_color=11823615
stops_color=17919

<window>
height=118

<indicator>
name=main
</indicator>

<indicator>
name=Custom Indicator
<expert>
name=Grid
flags=347
window_num=0
</expert>
show_data=0
</indicator>

<indicator>
name=Custom Indicator
<expert>
name=ChartInfos
flags=347
window_num=0
</expert>
show_data=0
</indicator>

<indicator>
name=Custom Indicator
<expert>
name=SuperBars
flags=339
window_num=0
</expert>
show_data=0
</indicator>

<indicator>
name=Custom Indicator
<expert>
name=Inside Bars
flags=339
window_num=0
<inputs>
Timeframe=H1
NumberOfInsideBars=3
</inputs>
</expert>
period_flags=3
show_data=0
</indicator>

<indicator>
name=Custom Indicator
<expert>
name=Moving Average
flags=339
window_num=0
<inputs>
MA.Periods=38
MA.Method=ALMA
UpTrend.Color=255
DownTrend.Color=255
Draw.Type=Line
Draw.Width=2
AutoConfiguration=0
</inputs>
</expert>
show_data=1
</indicator>

<indicator>
name=Custom Indicator
<expert>
name=Moving Average
flags=339
window_num=0
<inputs>
MA.Periods=46
MA.Method=ALMA
UpTrend.Color=16711680
DownTrend.Color=16711680
Draw.Type=Line
Draw.Width=2
AutoConfiguration=0
</inputs>
</expert>
show_data=1
</indicator>
</window>

<window>
height=25
fixed_height=0
<indicator>
name=Custom Indicator
<expert>
name=MACD
flags=339
window_num=1
<inputs>
FastMA.Periods=38
FastMA.Method=ALMA
SlowMA.Periods=46
SlowMA.Method=ALMA
MainLine.Width=0
</inputs>
</expert>
show_data=1
</indicator>
</window>

</chart>