//  Kali The Coder
//
//  Tanooki Labs, December 2020

import React from 'react';
import {
  SafeAreaView,
  StyleSheet,
  ScrollView,
  View,
  Text,
  StatusBar,
} from 'react-native';

const App: () => React$Node = () => {
  return (
    <>
      <StatusBar barStyle="dark-content" />
      <SafeAreaView
        style = { 
                    { backgroundColor: KaliColors.creamBackground } 
                }
      >
        <Text style = { 
                        { paddingTop: 20, paddingLeft: 20, paddingRight: 20, lineHeight: 46,
                          textAlign: "center", fontFamily: KaliFonts.pusab, fontSize: 64, color: '#24b4c1' } 
                      }>
        KALI THE CODER
        </Text>
        <View style = { { height: 20 } }/>
        <Text style = { 
                        { textAlign: "center", fontFamily: KaliFonts.pusab, fontSize: 24, color: '#ff8f0d',
                          lineHeight: 24} 
                      }>
        LEARN THE ABC's 
        </Text>
      </SafeAreaView>
    </>
  );
};

const KaliFonts = {
    pusab: 'Pusab'
}

const KaliColors = {
    creamBackground: '#FFF7E7'
}

const styles = StyleSheet.create({
});

export default App;
