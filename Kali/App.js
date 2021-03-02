//  Kali The Coder
//
//  Tanooki Labs, December 2020

import React from 'react';
import {
  Image,
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
                          textAlign: "center", fontFamily: KaliFonts.pusab, fontSize: 64, color: KaliColors.textTurquoise } 
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
        <View style = { { height: 20 } }/>
        <Image source = {require('./assets/images/group-100.png')}
               style = { { alignSelf: 'center', width: 240, height: 280, resizeMode: 'contain' } } 
        />
        <View style = { { height: 20 } }/>
        <View style = { { backgroundColor: '#FFFFFF', width: 300, height: 100, alignSelf: 'center'  } } >
            <Text style = { { textAlign: 'center', fontFamily: KaliFonts.pusab, fontSize: 24, color: KaliColors.textTurquoise,
                              lineHeight: 24, paddingTop: 10 } } >
                USING THE APP
            </Text>
            <View style = { { height: 10 } } />
            
        </View>
      </SafeAreaView>
    </>
  );
};

const KaliFonts = {
    pusab: 'Pusab'
}

const KaliColors = {
    creamBackground: '#FFF7E7',
    textTurquoise: '#24b4c1'
}

const styles = StyleSheet.create({
});

export default App;
