package com.google.sampling.experiential.datastore;

import java.util.List;

import junit.framework.TestCase;

import com.google.common.collect.Lists;
import com.google.paco.shared.model.ExperimentDAO;
import com.google.paco.shared.model.SignalingMechanismDAO;

public class JsonConverterTest extends TestCase {

  private List<ExperimentDAO> experimentList;

  protected void setUp() throws Exception {
    super.setUp();

    experimentList = Lists.newArrayList();
    experimentList.add(new ExperimentDAO());

    SignalingMechanismDAO[] signalingMechanisms = new SignalingMechanismDAO[1];
    signalingMechanisms[0] = null;
    String[] publishedAdmins = new String[1];
    publishedAdmins[0] = "example@example.com";
    experimentList.add(new ExperimentDAO(new Long(1), "1title", "1descr", "1consent", "1email",
                                         signalingMechanisms, true, false, null , null, null,
                                         null, null, false, publishedAdmins, publishedAdmins,
                                         false, false, 1, false, (String)null, true));
  }

  public void testShortJsonifyShortening() throws Exception {
    String longJson = JsonConverter.jsonify(experimentList);
    String shortJson = JsonConverter.shortJsonify(experimentList);
    assertTrue(shortJson.length() <= longJson.length());
  }

}
