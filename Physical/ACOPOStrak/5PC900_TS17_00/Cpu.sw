﻿<?xml version="1.0" encoding="utf-8"?>
<?AutomationStudio Version=4.7.3.93 SP?>
<SwConfiguration CpuAddress="SL1" xmlns="http://br-automation.co.at/AS/SwConfiguration">
  <TaskClass Name="Cyclic#1">
    <Task Name="Vis" Source="Trak.Vis.prg" Memory="UserROM" Language="IEC" Debugging="true" />
  </TaskClass>
  <TaskClass Name="Cyclic#2" />
  <TaskClass Name="Cyclic#3">
    <Task Name="DeltaIn" Source="Robots.DeltaIn.prg" Memory="UserROM" Language="IEC" Debugging="true" />
    <Task Name="DeltaOut" Source="Robots.DeltaOut.prg" Memory="UserROM" Language="IEC" Debugging="true" />
    <Task Name="TrakMoveme" Source="Trak.TrakMovement.prg" Memory="UserROM" Language="IEC" Debugging="true" />
  </TaskClass>
  <TaskClass Name="Cyclic#4">
    <Task Name="Recipe" Source="Recipe.prg" Memory="UserROM" Language="IEC" Debugging="true" />
    <Task Name="svgTransfo" Source="svgTransform.prg" Memory="UserROM" Language="IEC" Debugging="true" />
    <Task Name="Alarms" Source="Alarms.prg" Memory="UserROM" Language="IEC" Debugging="true" />
    <Task Name="SI" Source="Robots.SI.prg" Memory="UserROM" Language="IEC" Debugging="true" />
  </TaskClass>
  <TaskClass Name="Cyclic#5" />
  <TaskClass Name="Cyclic#6" />
  <TaskClass Name="Cyclic#7" />
  <TaskClass Name="Cyclic#8" />
  <DataObjects>
    <DataObject Name="McAcpSys" Source="" Memory="UserROM" Language="Binary" />
  </DataObjects>
  <Binaries>
    <BinaryObject Name="arsvcreg" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="udbdef" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="mvLoader" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="arflatprv" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="McProfGen" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="McAcpDrv" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="arcoal" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="FWRules" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="TCData" Source="" Memory="SystemROM" Language="Binary" />
    <BinaryObject Name="mCoWebSc" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="McAcpSim" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="McMechSys" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="TCLang" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="Config_1" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="ashwac" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="User" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="asfw" Source="" Memory="SystemROM" Language="Binary" />
    <BinaryObject Name="arconfig" Source="" Memory="SystemROM" Language="Binary" />
    <BinaryObject Name="Config_3" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="ashwd" Source="" Memory="SystemROM" Language="Binary" />
    <BinaryObject Name="Config_2" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="iomap" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="Role" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="Config_4" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="Hierarchy" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="Config" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="sysconf" Source="" Memory="SystemROM" Language="Binary" />
    <BinaryObject Name="Config_10" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="Config_5" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="Config_6" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="Config_7" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="Config_8" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="TC" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="Config_11" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="Config_9" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="Config_19" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="Config_18" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="Config_17" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="Config_16" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="Config_15" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="Config_14" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="Config_12" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="Config_13" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="AlarmHist" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="FileMeng" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="Alarm" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="Config_30" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="Config_20" Source="" Memory="UserROM" Language="Binary" />
  </Binaries>
  <Libraries>
    <LibraryObject Name="CoTrace" Source="Libraries.CoTrace.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="AsZip" Source="Libraries.AsZip.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="FileIO" Source="Libraries.FileIO.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="runtime" Source="Libraries.runtime.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="McBase" Source="Libraries.McBase.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="McAxis" Source="Libraries.McAxis.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="McAcpTrak" Source="Libraries.McAcpTrak.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="AsBrStr" Source="Libraries.AsBrStr.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="MpRobotics" Source="Libraries.MpRobotics.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="MpBase" Source="Libraries.MpBase.lby" Memory="UserROM" Language="Binary" Debugging="true" />
    <LibraryObject Name="McAxGroup" Source="Libraries.McAxGroup.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="McPathGen" Source="Libraries.McPathGen.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="McProgInt" Source="Libraries.McProgInt.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="McAcpAx" Source="Libraries.McAcpAx.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="MpRecipe" Source="Libraries.MpRecipe.lby" Memory="UserROM" Language="Binary" Debugging="true" />
    <LibraryObject Name="sys_lib" Source="Libraries.sys_lib.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="standard" Source="Libraries.standard.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="MpAlarmX" Source="Libraries.MpAlarmX.lby" Memory="UserROM" Language="Binary" Debugging="true" />
    <LibraryObject Name="astime" Source="Libraries.astime.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="MpFile" Source="Libraries.MpFile.lby" Memory="UserROM" Language="Binary" Debugging="true" />
    <LibraryObject Name="MpServer" Source="Libraries.MpServer.lby" Memory="UserROM" Language="Binary" Debugging="true" />
    <LibraryObject Name="arssl" Source="" Memory="UserROM" Language="Binary" Debugging="true" />
    <LibraryObject Name="asieccon" Source="" Memory="UserROM" Language="Binary" Debugging="true" />
    <LibraryObject Name="powerlnk" Source="" Memory="UserROM" Language="Binary" Debugging="true" />
    <LibraryObject Name="asarprof" Source="" Memory="UserROM" Language="Binary" Debugging="true" />
    <LibraryObject Name="asarlog" Source="" Memory="UserROM" Language="Binary" Debugging="true" />
    <LibraryObject Name="asmem" Source="" Memory="UserROM" Language="Binary" Debugging="true" />
    <LibraryObject Name="dataobj" Source="" Memory="UserROM" Language="Binary" Debugging="true" />
    <LibraryObject Name="brsystem" Source="" Memory="UserROM" Language="Binary" Debugging="true" />
    <LibraryObject Name="asusb" Source="" Memory="UserROM" Language="Binary" Debugging="true" />
    <LibraryObject Name="aruser" Source="" Memory="UserROM" Language="Binary" Debugging="true" />
  </Libraries>
</SwConfiguration>