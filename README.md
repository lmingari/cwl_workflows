# Run example for strong scaling

```
cwltool --outdir outputs workflows/miniapp_scaling.cwl arguments-scaling.yml
```

The workflow can be shown via:

```
cwltool --print-dot workflows/miniapp_scaling.cwl | dot -Tsvg > scaling.svg
```

![image](scaling.svg)

# Examples

More examples in the folder `workflows/`
