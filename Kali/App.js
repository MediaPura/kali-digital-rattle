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
  Dimensions
} from 'react-native';

const windowWidth = Dimensions.get('window').width;

const App: () => React$Node = () => {
  return (
    <>
      <StatusBar barStyle="dark-content" />
      <SafeAreaView
        style = { 
                    { backgroundColor: KaliColors.creamBackground } 
                }
      >
        <ScrollView>
            <Image source = { require('./assets/images/rainbow.png') }
                   style = { { position: 'absolute', left: -12, top: 418, width: (windowWidth + 20), height: 300 } }/>
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
            <View style = { { backgroundColor: KaliColors.white, width: 300, height: 100, alignSelf: 'center', borderRadius: 15  } } >
                <Text style = { { textAlign: 'center', fontFamily: KaliFonts.pusab, fontSize: 24, color: KaliColors.textTurquoise,
                                  lineHeight: 24, paddingTop: 10 } } >
                    USING THE APP
                </Text>
                <Text style = { {  textAlign: 'center', fontFamily: 'FreightSansProMedium-Regular', fontSize: 14, 
                                   color: KaliColors.textTurquoise, lineHeight: 16, paddingTop: 10 } }>
                    Be sure to enable sound on your Apple Watch.
                    Twisting the digital crown will rotate Kali for
                    other viewing options.
                </Text>
            </View>
            <View style = { { height: 20 } }/>
            <Text style = { 
                            { textAlign: "center", fontFamily: KaliFonts.pusab, fontSize: 24, color: '#ff8f0d',
                                    lineHeight: 24, textShadowColor: KaliColors.white, 
                                     textShadowOffset: { width: 1.5, height: 1.5 }, textShadowRadius: 1} 
                          }>
                THANK YOU FOR LEARNING WITH US! 
            </Text>
            <View style = { { height: 20 } }/>
            <Text style = { styles.footerText }>
                Questions or Support:
            </Text>
            <Text style = { styles.footerText }>
                email@kalithecoder.com | kalithecoder.com
            </Text>
            <View style = { { height: 20 } }/>
        </ScrollView>
      </SafeAreaView>
    </>
  );
};

const KaliFonts = {
    pusab: 'Pusab'
}

const KaliColors = {
    white: '#FFFFFF',
    creamBackground: '#FFF7E7',
    textTurquoise: '#24b4c1'
}

const styles = StyleSheet.create({
    footerText: {  textAlign: 'center', fontFamily: 'FreightSansProMedium-Regular', fontSize: 16, 
                   color: KaliColors.textTurquoise, lineHeight: 22
    }
});

export default App;
