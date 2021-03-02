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

import {
  Colors,
} from 'react-native/Libraries/NewAppScreen';

const App: () => React$Node = () => {
  return (
    <>
      <StatusBar barStyle="dark-content" />
      <SafeAreaView
        style = { 
                    { flex: 1, flexDirection: "row", backgroundColor: KaliColors.creamBackground } 
                }
      >
        <Text style = { 
                        { marginTop: 10, fontFamily: 'Pusab', fontSize: 32, color: '#24b4c1' } 
                      }>
        Kali The Coder
        </Text>
      </SafeAreaView>
    </>
  );
};

const KaliColors = {
    creamBackground: '#FFF7E7'
}

const styles = StyleSheet.create({
});

export default App;
