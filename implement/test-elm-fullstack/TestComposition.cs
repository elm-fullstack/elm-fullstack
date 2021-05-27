using System.Collections.Immutable;
using System.Linq;
using System.Text;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Pine;

namespace test_elm_fullstack
{
    [TestClass]
    public class TestComposition
    {
        [TestMethod]
        public void Composition_from_tree_with_string_path()
        {
            var testCases = new[]
            {
                new
                {
                    input = Composition.TreeWithStringPath.Blob(new byte[]{0,1,2}.ToImmutableList()),
                    expectedOutput = Composition.Component.Blob(new byte[]{0,1,2}.ToImmutableList())
                },
                new
                {
                    input = Composition.TreeWithStringPath.Tree(
                        new []
                        {
                            (name: "ABC ä 😀",
                            component: Composition.TreeWithStringPath.Blob(new byte[]{0,1,2,3}.ToImmutableList()) ),
                        }.ToImmutableList()),
                    expectedOutput = Composition.Component.List(
                        new[]
                        {
                            Composition.Component.List(
                                new[]
                                {
                                    Composition.Component.List(
                                        new[]
                                        {
                                            Composition.Component.Blob(ImmutableList.Create<byte>(65)),
                                            Composition.Component.Blob(ImmutableList.Create<byte>(66)),
                                            Composition.Component.Blob(ImmutableList.Create<byte>(67)),
                                            Composition.Component.Blob(ImmutableList.Create<byte>(32)),
                                            Composition.Component.Blob(ImmutableList.Create<byte>(228)),
                                            Composition.Component.Blob(ImmutableList.Create<byte>(32)),
                                            Composition.Component.Blob(ImmutableList.Create<byte>(1,246,0)),
                                        }.ToImmutableList()
                                    ),
                                    Composition.Component.Blob(new byte[]{0,1,2,3}.ToImmutableList() )
                                }.ToImmutableList()
                            )
                        }.ToImmutableList())
                    },
                };

            foreach (var testCase in testCases)
            {
                var asComposition = Composition.FromTreeWithStringPath(testCase.input);

                Assert.AreEqual(testCase.expectedOutput, asComposition);
            }
        }

        [TestMethod]
        public void Parse_as_tree_with_string_path()
        {
            var testCases = new[]
            {
                new
                {
                    input = Composition.Component.Blob(new byte[]{0,1,2}),
                    expectedOutput = new Composition.ParseAsTreeWithStringPathResult
                    {
                        Ok = Composition.TreeWithStringPath.Blob(new byte[]{0,1,2})
                    }
                },
                new
                {
                    input = new Composition.Component
                    {
                        ListContent = new[]
                        {
                            new Composition.Component
                            {
                                ListContent = new[]
                                {
                                    new Composition.Component
                                    {
                                        ListContent = new []
                                        {
                                            new Composition.Component{BlobContent = ImmutableList.Create<byte>(68)},
                                            new Composition.Component{BlobContent = ImmutableList.Create<byte>(69)},
                                            new Composition.Component{BlobContent = ImmutableList.Create<byte>(70)},
                                            new Composition.Component{BlobContent = ImmutableList.Create<byte>(32)},
                                            new Composition.Component{BlobContent = ImmutableList.Create<byte>(1,243,50)},
                                        }.ToImmutableList(),
                                    },
                                    new Composition.Component{ BlobContent = new byte[]{0,1,2,3}.ToImmutableList() }
                                }.ToImmutableList()
                            }
                        }.ToImmutableList()
                    },
                    expectedOutput = new Composition.ParseAsTreeWithStringPathResult
                    {
                        Ok = new Composition.TreeWithStringPath
                        {
                            TreeContent = new []
                            {
                                (name: "DEF 🌲",
                                component: new Composition.TreeWithStringPath{ BlobContent = new byte[]{0,1,2,3}.ToImmutableList()} ),
                            }.ToImmutableList()
                        }
                    }
                },
            };

            foreach (var testCase in testCases)
            {
                var parseResult = Composition.ParseAsTreeWithStringPath(testCase.input);

                Assert.AreEqual(testCase.expectedOutput, parseResult);
            }
        }

        [TestMethod]
        public void Composition_from_file_tree()
        {
            var testCases = new[]
            {
                new
                {
                    input = new []
                    {
                        (filePath: "a", fileContent: new byte[]{0,1,2}),
                        (filePath: "b/c", fileContent: new byte[]{3,4,5,6}),
                        (filePath: "b/d", fileContent: new byte[]{7,8}),
                    },
                    expectedOutput = new Composition.Component
                    {
                        ListContent = new []
                        {
                            new Composition.Component
                            {
                                ListContent = new []
                                {
                                    new Composition.Component
                                    {
                                        ListContent = new []
                                        {
                                            new Composition.Component{BlobContent = ImmutableList.Create<byte>(97)},
                                        }.ToImmutableList(),
                                    },
                                    new Composition.Component{ BlobContent = new byte[]{0,1,2}.ToImmutableList()},
                                }.ToImmutableList()
                            },
                            new Composition.Component
                            {
                                ListContent = new []
                                {
                                    new Composition.Component
                                    {
                                        ListContent = new []
                                        {
                                            new Composition.Component{BlobContent = ImmutableList.Create<byte>(98)},
                                        }.ToImmutableList(),
                                    },
                                    new Composition.Component
                                    {
                                        ListContent = new []
                                        {
                                            new Composition.Component
                                            {
                                                ListContent = new []
                                                {
                                                    new Composition.Component
                                                    {
                                                        ListContent = new []
                                                        {
                                                            new Composition.Component{BlobContent = ImmutableList.Create<byte>(99)},
                                                        }.ToImmutableList(),
                                                    },
                                                    new Composition.Component{ BlobContent = new byte[]{3,4,5,6}.ToImmutableList()},
                                                }.ToImmutableList()
                                            },
                                            new Composition.Component
                                            {
                                                ListContent = new []
                                                {
                                                    new Composition.Component
                                                    {
                                                        ListContent = new []
                                                        {
                                                            new Composition.Component{BlobContent = ImmutableList.Create<byte>(100)},
                                                        }.ToImmutableList(),
                                                    },
                                                    new Composition.Component{ BlobContent = new byte[]{7,8}.ToImmutableList()},
                                                }.ToImmutableList()
                                            },
                                        }.ToImmutableList()
                                    }
                                }.ToImmutableList()
                            },
                        }.ToImmutableList()
                    }
                },
            };

            foreach (var testCase in testCases)
            {
                var asComposition = Composition.FromTreeWithStringPath(
                    Composition.SortedTreeFromSetOfBlobsWithCommonFilePath(testCase.input));

                Assert.AreEqual(testCase.expectedOutput, asComposition);
            }
        }

        [TestMethod]
        public void Hash_composition()
        {
            var testCases = new[]
            {
                new
                {
                    input = new Composition.Component
                    {
                        BlobContent = new byte[]{0,1,2}.ToImmutableList()
                    },
                    expectedHashBase16 = CommonConversion.StringBase16FromByteArray(
                        CommonConversion.HashSHA256(Encoding.ASCII.GetBytes("blob 3\0").Concat(new byte[]{0,1,2}).ToArray()))
                },
            };

            foreach (var testCase in testCases)
            {
                var hash = Composition.GetHash(testCase.input);

                Assert.AreEqual(testCase.expectedHashBase16, CommonConversion.StringBase16FromByteArray(hash), ignoreCase: true);
            }
        }

        [TestMethod]
        public void String_value_roundtrips()
        {
            var testCases = new[]
            {
                "",
                "Hello World!",
                "Using some non-ASCII chars: 🌀 𝅘𝅥𝅰𝆁  𝅘𝅥𝅰 𝆁◌ 𝅘 𝅥 𝅰 𝆁◌ 😃 ⚠️☢️✔️",
            };

            foreach (var testCase in testCases)
            {
                var asPineValue =
                    Composition.ComponentFromString(testCase);

                var toStringResult =
                    Composition.StringFromComponent(asPineValue);

                Assert.IsNull(toStringResult.Err);

                Assert.AreEqual(testCase, toStringResult.Ok);
            }
        }

        [TestMethod]
        public void Signed_Integer_value_roundtrips()
        {
            var testCases = new[]
            {
                0,-1,1,-1234,2345,123456789
            };

            foreach (var testCase in testCases)
            {
                var asPineValue =
                    Composition.ComponentFromSignedInteger(testCase);

                var toIntegerResult =
                    Composition.SignedIntegerFromComponent(asPineValue);

                Assert.IsNull(toIntegerResult.Err);

                Assert.AreEqual(testCase, toIntegerResult.Ok);
            }
        }

        [TestMethod]
        public void Unsigned_Integer_value_roundtrips()
        {
            var testCases = new[]
            {
                0,1,1234,2345,123456789
            };

            foreach (var testCase in testCases)
            {
                var asPineValue =
                    Composition.ComponentFromUnsignedInteger(testCase);

                Assert.IsNull(asPineValue.Err);

                var toIntegerResult =
                    Composition.UnsignedIntegerFromComponent(asPineValue.Ok);

                Assert.IsNull(toIntegerResult.Err);

                Assert.AreEqual(testCase, toIntegerResult.Ok);
            }

            Assert.IsNotNull(Composition.ComponentFromUnsignedInteger(-1).Err);
        }

        [TestMethod]
        public void Tree_with_string_path_sorting()
        {
            var testCases = new[]
            {
                new
                {
                    input = new Composition.TreeWithStringPath
                    {
                        TreeContent = ImmutableList.Create(
                            ("ba-", Composition.TreeWithStringPath.blob(ImmutableList.Create<byte>(0))),
                            ("ba", Composition.TreeWithStringPath.blob(ImmutableList.Create<byte>(1))),
                            ("bb", Composition.TreeWithStringPath.blob(ImmutableList.Create<byte>(2))),
                            ("a", Composition.TreeWithStringPath.blob(ImmutableList.Create<byte>(3))),
                            ("test😃", Composition.TreeWithStringPath.blob(ImmutableList.Create<byte>(4))),
                            ("testa", Composition.TreeWithStringPath.blob(ImmutableList.Create<byte>(5))),
                            ("tesz", Composition.TreeWithStringPath.blob(ImmutableList.Create<byte>(6))),
                            ("", Composition.TreeWithStringPath.blob(ImmutableList.Create<byte>(7))),
                            ("🌿", Composition.TreeWithStringPath.blob(ImmutableList.Create<byte>(8))),
                            ("🌲", Composition.TreeWithStringPath.blob(ImmutableList.Create<byte>(9))),
                            ("c", new Composition.TreeWithStringPath
                            {
                                TreeContent = ImmutableList.Create(
                                    ("gamma", Composition.TreeWithStringPath.blob(ImmutableList.Create<byte>(10))),
                                    ("alpha", Composition.TreeWithStringPath.blob(ImmutableList.Create<byte>(11)))
                                    ),
                            }),
                            ("bA", Composition.TreeWithStringPath.blob(ImmutableList.Create<byte>(12)))
                            ),
                    },
                    expected = new Composition.TreeWithStringPath
                    {
                        TreeContent = ImmutableList.Create(
                            ("", Composition.TreeWithStringPath.blob(ImmutableList.Create<byte>(7))),
                            ("a", Composition.TreeWithStringPath.blob(ImmutableList.Create<byte>(3))),
                            ("bA", Composition.TreeWithStringPath.blob(ImmutableList.Create<byte>(12))),
                            ("ba", Composition.TreeWithStringPath.blob(ImmutableList.Create<byte>(1))),
                            ("ba-", Composition.TreeWithStringPath.blob(ImmutableList.Create<byte>(0))),
                            ("bb", Composition.TreeWithStringPath.blob(ImmutableList.Create<byte>(2))),
                            ("c", new Composition.TreeWithStringPath
                            {
                                TreeContent = ImmutableList.Create(
                                    ("alpha", Composition.TreeWithStringPath.blob(ImmutableList.Create<byte>(11))),
                                    ("gamma", Composition.TreeWithStringPath.blob(ImmutableList.Create<byte>(10)))
                                    ),
                            }),
                            ("testa", Composition.TreeWithStringPath.blob(ImmutableList.Create<byte>(5))),
                            ("test😃", Composition.TreeWithStringPath.blob(ImmutableList.Create<byte>(4))),
                            ("tesz", Composition.TreeWithStringPath.blob(ImmutableList.Create<byte>(6))),
                            ("🌲", Composition.TreeWithStringPath.blob(ImmutableList.Create<byte>(9))),
                            ("🌿", Composition.TreeWithStringPath.blob(ImmutableList.Create<byte>(8)))
                            ),
                    },
                }
            };

            foreach (var testCase in testCases)
            {
                var sortedTree = Composition.SortedTreeFromTree(testCase.input);

                Assert.AreEqual(expected: testCase.expected, sortedTree);
            }
        }

        [TestMethod]
        public void Runtime_expenses_hash()
        {
            var blobImmutableList = Enumerable.Range(0, 1_000_000).Select(i => (byte)i).ToImmutableList();
            var blobArray = blobImmutableList.ToArray();

            var listStopwatch = System.Diagnostics.Stopwatch.StartNew();
            var hashFromList = Composition.GetHash(Composition.Component.Blob(blobImmutableList));
            listStopwatch.Stop();

            // Test the case found in blob library: Start from array:

            var arrayStopwatch = System.Diagnostics.Stopwatch.StartNew();
            var hashFromArray = Composition.GetHash(Composition.Component.Blob(blobArray));
            arrayStopwatch.Stop();

            System.Console.WriteLine("list ms: " + listStopwatch.ElapsedMilliseconds + ", array ms: " + arrayStopwatch.ElapsedMilliseconds);

            CollectionAssert.AreEqual(hashFromList, hashFromArray);
        }
    }
}
